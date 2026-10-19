//
//  AssignmentsView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import SwiftUI

struct AssignmentsView: View {
    @State private var courseGroups: [AssignmentsData]?

    @State private var isLoading = false
    @State private var errorToast: ToastState = .errorTitle

    @State private var isNotificationDeniedAlertPresented = false

    @State private var isInitial = true

    var body: some View {
        AssignmentsContent(
            courseGroups: courseGroups,
            isLoading: isLoading,
            isNotificationEnabled: MMKVHelper.Assignments.isNotificationEnabled,
            notificationOffsetHour: MMKVHelper.Assignments.notificationOffsetHour,
            notificationOffsetMinute: MMKVHelper.Assignments.notificationOffsetMinute,
            errorToast: $errorToast,
            isNotificationDeniedAlertPresented: $isNotificationDeniedAlertPresented,
            onRefreshAssignments: loadAssignments,
            onSaveNotificationSettings: saveNotificationSettings,
            onOpenNotificationSettings: openNotificationSettings
        )
        .onReceive(MMKVHelper.Assignments.$cache.dropFirst().receive(on: RunLoop.main)) { data in
            applyData(data)
        }
        .task {
            guard isInitial else {
                return
            }
            isInitial = false

            applyData(MMKVHelper.Assignments.cache)

            await syncTodoNotificationsSilently()
            await loadAssignments()
        }
    }

    // MARK: - Methods

    private func loadAssignments() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let courses = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCoursesWithPendingAssignments()
            }
            var newGroups: [AssignmentsData] = []

            for course in courses {
                let assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                    try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
                }
                newGroups.append(.init(course: course, assignments: assignments))
            }

            let data = Cached(cachedAt: .now, value: newGroups)
            MMKVHelper.Assignments.cache = data
            WidgetTimelineRefreshHelper.reloadAssignments()

            let drafts = AssignmentsNotificationHelper.buildLocalNotificationDrafts(
                groups: data.value,
                reminderOffsetHour: MMKVHelper.Assignments.notificationOffsetHour,
                reminderOffsetMinute: MMKVHelper.Assignments.notificationOffsetMinute
            )
            await AssignmentsNotificationHelper.syncTodoNotificationsSilently(
                isNotificationEnabled: MMKVHelper.Assignments.isNotificationEnabled,
                drafts: drafts,
                onPermissionDenied: {
                    MMKVHelper.Assignments.isNotificationEnabled = false
                }
            )
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyData(_ data: Cached<[AssignmentsData]>?) {
        courseGroups = data?.value
    }

    private func openNotificationSettings() {
        NotificationManager.shared.openAppNotificationSettings()
        isNotificationDeniedAlertPresented = false
    }

    private func saveNotificationSettings(enabled: Bool, hour: Int, minute: Int) async {
        let wasNotificationEnabled = MMKVHelper.Assignments.isNotificationEnabled
        MMKVHelper.Assignments.notificationOffsetHour = hour
        MMKVHelper.Assignments.notificationOffsetMinute = minute

        if enabled == wasNotificationEnabled {
            if enabled {
                await syncTodoNotificationsInteractively()
            } else {
                await NotificationManager.shared.clearLocalNotifications(prefix: AssignmentsNotificationHelper.notificationPrefix)
            }
            return
        }

        await updateTodoNotificationEnabled(enabled)
    }

    private func updateTodoNotificationEnabled(_ enabled: Bool) async {
        if !enabled {
            MMKVHelper.Assignments.isNotificationEnabled = false
            await NotificationManager.shared.clearLocalNotifications(prefix: AssignmentsNotificationHelper.notificationPrefix)
            return
        }

        await NotificationManager.shared.updatePermissionStatus()
        let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

        do {
            switch permissionStatus {
            case .authorized:
                MMKVHelper.Assignments.isNotificationEnabled = true
                await syncTodoNotificationsInteractively()
            case .denied:
                MMKVHelper.Assignments.isNotificationEnabled = false
                isNotificationDeniedAlertPresented = true
            case .requestable:
                guard try await NotificationManager.shared.requestPermission() else {
                    MMKVHelper.Assignments.isNotificationEnabled = false
                    isNotificationDeniedAlertPresented = true
                    return
                }
                MMKVHelper.Assignments.isNotificationEnabled = true
                await syncTodoNotificationsInteractively()
            }
        } catch {
            MMKVHelper.Assignments.isNotificationEnabled = false
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func syncTodoNotificationsSilently() async {
        let drafts = AssignmentsNotificationHelper.buildLocalNotificationDrafts(
            groups: courseGroups ?? [],
            reminderOffsetHour: MMKVHelper.Assignments.notificationOffsetHour,
            reminderOffsetMinute: MMKVHelper.Assignments.notificationOffsetMinute
        )

        await AssignmentsNotificationHelper.syncTodoNotificationsSilently(
            isNotificationEnabled: MMKVHelper.Assignments.isNotificationEnabled,
            drafts: drafts,
            onPermissionDenied: {
                MMKVHelper.Assignments.isNotificationEnabled = false
            }
        )
    }

    private func syncTodoNotificationsInteractively() async {
        do {
            await NotificationManager.shared.updatePermissionStatus()
            let permissionStatus = NotificationManager.shared.permissionStatus ?? .requestable

            if permissionStatus == .denied {
                MMKVHelper.Assignments.isNotificationEnabled = false
                isNotificationDeniedAlertPresented = true
                return
            }

            guard permissionStatus == .authorized else {
                errorToast.show(message: "通知权限未开启")
                return
            }

            guard MMKVHelper.Assignments.isNotificationEnabled else {
                await NotificationManager.shared.clearLocalNotifications(prefix: AssignmentsNotificationHelper.notificationPrefix)
                return
            }

            let drafts = AssignmentsNotificationHelper.buildLocalNotificationDrafts(
                groups: courseGroups ?? [],
                reminderOffsetHour: MMKVHelper.Assignments.notificationOffsetHour,
                reminderOffsetMinute: MMKVHelper.Assignments.notificationOffsetMinute
            )
            try await NotificationManager.shared.syncLocalNotifications(prefix: AssignmentsNotificationHelper.notificationPrefix, drafts: drafts)
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}

@MainActor
enum AssignmentsNotificationHelper {
    static let notificationPrefix = "todo-assignments."
    private static let notificationThread = "todo-assignments.thread"

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

    static func buildLocalNotificationDrafts(
        groups: [AssignmentsData],
        reminderOffsetHour: Int,
        reminderOffsetMinute: Int
    ) -> [LocalNotificationDraft] {
        let reminderOffsetSeconds = reminderOffsetSeconds(
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
        TimeInterval(hour * 3600 + minute * 60)
    }
}

extension MMKVHelper.Assignments {
    @MMKVStorage(key: "TodoAssignments.isNotificationEnabled", defaultValue: false)
    static var isNotificationEnabled: Bool

    @MMKVStorage(key: "TodoAssignments.notificationOffsetHour", defaultValue: 2)
    static var notificationOffsetHour: Int

    @MMKVStorage(key: "TodoAssignments.notificationOffsetMinute", defaultValue: 0)
    static var notificationOffsetMinute: Int
}
