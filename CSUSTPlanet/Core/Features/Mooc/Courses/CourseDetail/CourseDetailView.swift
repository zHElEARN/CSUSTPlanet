//
//  CourseDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/23.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseDetailView: View {
    let course: MoocHelper.Course

    @State private var assignments: [MoocHelper.Assignment] = []

    @State private var isLoading = false

    @State private var errorToast: ToastState = .errorTitle

    @State private var isInitial = true

    // MARK: - Body

    var body: some View {
        CourseDetailContent(
            course: course,
            assignments: assignments,
            isLoading: isLoading,
            errorToast: $errorToast,
            onRefreshAssignments: {
                await loadAssignments(course: course)
            }
        )
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            await loadAssignments(course: course)
        }
    }

    // MARK: - Methods

    private func loadAssignments(course: MoocHelper.Course) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
