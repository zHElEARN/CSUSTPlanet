//
//  AssignmentsOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class AssignmentsOverviewViewModel {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var assignmentsData: Cached<[AssignmentsData]>?

    @ObservationIgnored var isFirstObservation = true
    var isLoadingAssignments = false

    var submittableAssignments: [(courseName: String, assignment: MoocHelper.Assignment)] {
        guard let groups = assignmentsData?.value else { return [] }

        return
            groups
            .flatMap { group in
                group.assignments.compactMap { assignment in
                    guard assignment.canSubmit, !assignment.submitStatus else { return nil }
                    return (courseName: group.course.name, assignment: assignment)
                }
            }
            .sorted { $0.assignment.deadline < $1.assignment.deadline }
    }

    var cachedAt: Date? {
        assignmentsData?.cachedAt
    }

    init() {
        MMKVHelper.Assignments.$cache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if isFirstObservation {
                    self.assignmentsData = data
                    isFirstObservation = false
                } else {
                    withAnimation {
                        self.assignmentsData = data
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadAssignments() async {
        guard !isLoadingAssignments else { return }
        isLoadingAssignments = true
        defer { isLoadingAssignments = false }

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
            // [INFO] 暂时不处理错误
        }
    }
}
