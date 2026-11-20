//
//  AssignmentsContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import SwiftUI

struct AssignmentsContent: View {
    let courseGroups: [AssignmentsData]?
    let isLoading: Bool

    @Binding var errorToast: ToastState

    let onRefreshAssignments: () async -> Void

    private var submittableAssignmentsCount: Int {
        let referenceDate = Date.now
        return (courseGroups ?? []).reduce(0) { count, group in
            count + group.assignments.filter { $0.isSubmittable(referenceDate: referenceDate) }.count
        }
    }

    var body: some View {
        ListPageScaffold(
            title: "作业列表",
            subtitle: "共\(submittableAssignmentsCount)个可提交作业",
            isEmpty: courseGroups?.isEmpty ?? true,
            isLoading: isLoading,
            emptyNoun: "作业",
            errorToast: $errorToast,
            onQuery: onRefreshAssignments
        ) {
            ForEach(courseGroups ?? [], id: \.course.id) { group in
                AssignmentsCourseSection(group: group)
            }
        }
    }
}
