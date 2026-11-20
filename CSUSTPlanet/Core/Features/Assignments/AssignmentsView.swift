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

    @State private var isInitial = true

    var body: some View {
        AssignmentsContent(
            courseGroups: courseGroups,
            isLoading: isLoading,
            errorToast: $errorToast,
            onRefreshAssignments: loadAssignments
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
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyData(_ data: Cached<[AssignmentsData]>?) {
        courseGroups = data?.value
    }
}
