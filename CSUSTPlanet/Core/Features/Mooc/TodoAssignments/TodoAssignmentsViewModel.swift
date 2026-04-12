//
//  TodoAssignmentsViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import SwiftUI

@MainActor
@Observable
final class TodoAssignmentsViewModel {
    var todoAssignmentsData: Cached<[TodoAssignmentsData]>? = nil

    private var unexpiredAssignmentsByCourseID: [String: [MoocHelper.Assignment]] = [:]
    private(set) var unexpiredAssignmentsCount: Int = 0

    var expandedCourseIDs: Set<String> = []
    var showAllAssignmentsCourseIDs: Set<String> = []

    var isLoadingAssignments = false

    var errorToast: ToastState = .errorTitle

    var isNotificationDeniedAlertPresented = false
    var isNotificationSettingsPresented = false

    var isTodoAssignmentsNotificationEnabled = false {
        didSet { MMKVHelper.TodoAssignments.isNotificationEnabled = isTodoAssignmentsNotificationEnabled }
    }

    var reminderOffsetHour = 2 {
        didSet { MMKVHelper.TodoAssignments.notificationOffsetHour = reminderOffsetHour }
    }

    var reminderOffsetMinute = 0 {
        didSet { MMKVHelper.TodoAssignments.notificationOffsetMinute = reminderOffsetMinute }
    }

    @ObservationIgnored var isInitial = true

    private static let notificationPrefix = "todo-assignments."
    private static let notificationThread = "todo-assignments.thread"

    init() {
        isTodoAssignmentsNotificationEnabled = MMKVHelper.TodoAssignments.isNotificationEnabled
        reminderOffsetHour = min(max(MMKVHelper.TodoAssignments.notificationOffsetHour, 0), 72)
        reminderOffsetMinute = min(max(MMKVHelper.TodoAssignments.notificationOffsetMinute, 0), 59)

        guard let data = MMKVHelper.TodoAssignments.cache else { return }
        applyData(data)
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await syncTodoNotificationsSilently()
        await loadTodoAssignments()
    }

    func loadTodoAssignments() async {
        guard !isLoadingAssignments else { return }
        isLoadingAssignments = true
        defer { isLoadingAssignments = false }

        do {
            let courses = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCoursesWithPendingAssignments()
            }
            var newGroups: [TodoAssignmentsData] = []

            for course in courses {
                let assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                    try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
                }
                newGroups.append(.init(course: course, assignments: assignments))
            }

            let data = Cached(cachedAt: .now, value: newGroups)
            applyData(data)
            MMKVHelper.TodoAssignments.cache = data
            WidgetTimelineRefreshHelper.reloadTodoAssignments()
            await syncTodoNotificationsSilently()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func updateTodoNotificationEnabled(_ enabled: Bool) async {
        if !enabled {
            isTodoAssignmentsNotificationEnabled = false
            await NotificationManager.shared.clearLocalNotifications(prefix: Self.notificationPrefix)
            return
        }

        await NotificationManager.shared.updatePermissionStatus()
        let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

        do {
            switch permissionStatus {
            case .authorized:
                isTodoAssignmentsNotificationEnabled = true
                await syncTodoNotificationsInteractively()
            case .denied:
                isTodoAssignmentsNotificationEnabled = false
                isNotificationDeniedAlertPresented = true
            case .requestable:
                guard try await NotificationManager.shared.requestPermission() else {
                    isTodoAssignmentsNotificationEnabled = false
                    isNotificationDeniedAlertPresented = true
                    return
                }
                isTodoAssignmentsNotificationEnabled = true
                await syncTodoNotificationsInteractively()
            }
        } catch {
            isTodoAssignmentsNotificationEnabled = false
            errorToast.show(message: error.localizedDescription)
        }
    }

    func saveNotificationSettings(enabled: Bool, hour: Int, minute: Int) async {
        reminderOffsetHour = min(max(hour, 0), 72)
        reminderOffsetMinute = min(max(minute, 0), 59)

        if enabled == isTodoAssignmentsNotificationEnabled {
            if enabled {
                await syncTodoNotificationsInteractively()
            } else {
                await NotificationManager.shared.clearLocalNotifications(prefix: Self.notificationPrefix)
            }
            return
        }

        await updateTodoNotificationEnabled(enabled)
    }

    func syncTodoNotificationsSilently() async {
        let drafts = buildLocalNotificationDrafts()

        await Self.syncTodoNotificationsSilently(
            isNotificationEnabled: isTodoAssignmentsNotificationEnabled,
            drafts: drafts,
            onPermissionDenied: {
                self.isTodoAssignmentsNotificationEnabled = false
            }
        )
    }

    static func syncTodoNotificationsSilently(
        isNotificationEnabled: Bool,
        drafts: [LocalNotificationDraft],
        onPermissionDenied: () -> Void = {}
    ) async {
        do {
            await NotificationManager.shared.updatePermissionStatus()
            let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

            if permissionStatus == .denied {
                if isNotificationEnabled {
                    onPermissionDenied()
                }
                return
            }

            guard isNotificationEnabled else {
                await NotificationManager.shared.clearLocalNotifications(prefix: notificationPrefix)
                return
            }

            guard permissionStatus == .authorized else { return }

            try await NotificationManager.shared.syncLocalNotifications(prefix: notificationPrefix, drafts: drafts)
        } catch {}
    }

    func syncTodoNotificationsInteractively() async {
        do {
            await NotificationManager.shared.updatePermissionStatus()
            let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

            if permissionStatus == .denied {
                isTodoAssignmentsNotificationEnabled = false
                isNotificationDeniedAlertPresented = true
                return
            }

            guard permissionStatus == .authorized else {
                errorToast.show(message: "通知权限未开启")
                return
            }

            guard isTodoAssignmentsNotificationEnabled else {
                await NotificationManager.shared.clearLocalNotifications(prefix: Self.notificationPrefix)
                return
            }

            try await NotificationManager.shared.syncLocalNotifications(prefix: Self.notificationPrefix, drafts: buildLocalNotificationDrafts())
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func isExpanded(courseID: String) -> Bool {
        expandedCourseIDs.contains(courseID)
    }

    func setExpanded(_ isExpanded: Bool, courseID: String) {
        if isExpanded {
            expandedCourseIDs.insert(courseID)
        } else {
            expandedCourseIDs.remove(courseID)
        }
    }

    func toggleExpanded(courseID: String) {
        if expandedCourseIDs.contains(courseID) {
            expandedCourseIDs.remove(courseID)
        } else {
            expandedCourseIDs.insert(courseID)
        }
    }

    func isShowingAllAssignments(courseID: String) -> Bool {
        showAllAssignmentsCourseIDs.contains(courseID)
    }

    func toggleShowAllAssignments(courseID: String) {
        if showAllAssignmentsCourseIDs.contains(courseID) {
            showAllAssignmentsCourseIDs.remove(courseID)
        } else {
            showAllAssignmentsCourseIDs.insert(courseID)
        }
    }

    func displayedAssignments(for group: TodoAssignmentsData) -> [MoocHelper.Assignment] {
        if isShowingAllAssignments(courseID: group.course.id) {
            return group.assignments
        }

        return unexpiredAssignmentsByCourseID[group.course.id] ?? []
    }

    private func applyData(_ data: Cached<[TodoAssignmentsData]>) {
        todoAssignmentsData = data

        let referenceDate = Date.now
        var unexpiredMap: [String: [MoocHelper.Assignment]] = [:]
        var totalCount = 0

        for group in data.value {
            let unexpiredAssignments = group.assignments.filter { $0.deadline >= referenceDate }
            unexpiredMap[group.course.id] = unexpiredAssignments
            totalCount += unexpiredAssignments.count
        }

        unexpiredAssignmentsByCourseID = unexpiredMap
        unexpiredAssignmentsCount = totalCount

        let existingCourseIDs = Set(data.value.map(\.course.id))
        expandedCourseIDs = existingCourseIDs
        showAllAssignmentsCourseIDs = showAllAssignmentsCourseIDs.intersection(existingCourseIDs)
    }

    private func buildLocalNotificationDrafts() -> [LocalNotificationDraft] {
        Self.buildLocalNotificationDrafts(
            groups: todoAssignmentsData?.value ?? [],
            reminderOffsetHour: reminderOffsetHour,
            reminderOffsetMinute: reminderOffsetMinute
        )
    }

    static func buildLocalNotificationDrafts(
        groups: [TodoAssignmentsData],
        reminderOffsetHour: Int,
        reminderOffsetMinute: Int
    ) -> [LocalNotificationDraft] {
        let reminderOffsetSeconds = Self.reminderOffsetSeconds(
            hour: reminderOffsetHour,
            minute: reminderOffsetMinute
        )
        let now = Date.now

        return groups.flatMap { group in
            group.assignments.compactMap { assignment in
                guard assignment.canSubmit else { return nil }
                guard !assignment.submitStatus else { return nil }
                guard assignment.deadline > now else { return nil }

                let triggerDate = assignment.deadline.addingTimeInterval(-reminderOffsetSeconds)
                guard triggerDate > now else { return nil }

                let identifier = "\(notificationPrefix)\(group.course.id).\(assignment.id)"

                return LocalNotificationDraft(
                    identifier: identifier,
                    threadIdentifier: notificationThread,
                    title: "作业截止提醒",
                    subtitle: group.course.name,
                    body: "\(assignment.title) 将在 \(assignment.deadline.formatted(.dateTime.month().day().hour().minute())) 截止",
                    triggerDate: triggerDate,
                    userInfo: [:]
                )
            }
        }
    }

    private static func reminderOffsetSeconds(hour: Int, minute: Int) -> TimeInterval {
        let clampedHour = min(max(hour, 0), 72)
        let clampedMinute = min(max(minute, 0), 59)
        return TimeInterval(clampedHour * 3600 + clampedMinute * 60)
    }
}

extension MMKVHelper.TodoAssignments {
    @MMKVStorage(key: "TodoAssignments.isNotificationEnabled", defaultValue: false)
    static var isNotificationEnabled: Bool

    @MMKVStorage(key: "TodoAssignments.notificationOffsetHour", defaultValue: 2)
    static var notificationOffsetHour: Int

    @MMKVStorage(key: "TodoAssignments.notificationOffsetMinute", defaultValue: 0)
    static var notificationOffsetMinute: Int
}
