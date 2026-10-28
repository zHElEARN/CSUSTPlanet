//
//  CourseDetailContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import SwiftUI

struct CourseDetailContent: View {
    let course: MoocHelper.Course
    let assignments: [MoocHelper.Assignment]

    let isLoading: Bool

    @Binding var errorToast: ToastState

    let onRefreshAssignments: () async -> Void

    var body: some View {
        CustomScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CourseInfoSection(course: course)
                CourseAssignmentsSection(
                    assignments: assignments,
                    isLoading: isLoading,
                    onRefresh: onRefreshAssignments
                )
            }
            .padding()
        }
        .errorToast($errorToast)
        .navigationTitle(course.name)
        .apply { view in
            if let teacher = course.teacher {
                view.navigationSubtitleCompat("\(teacher)老师")
            } else {
                view
            }
        }
    }
}
