//
//  AssignmentOverviewViewModel.swift
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
final class AssignmentOverviewViewModel {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var todoAssignmentsData: Cached<[TodoAssignmentsData]>?

    @ObservationIgnored var isFirstObservation = true
    var isLoadingAssignments = false

    var submittableAssignments: [(courseName: String, assignment: MoocHelper.Assignment)] {
        guard let groups = todoAssignmentsData?.value else { return [] }

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
        todoAssignmentsData?.cachedAt
    }

    init() {
        MMKVHelper.TodoAssignments.$cache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if isFirstObservation {
                    isFirstObservation = false
                    self.todoAssignmentsData = data
                } else {
                    withAnimation {
                        self.todoAssignmentsData = data
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
            var newGroups: [TodoAssignmentsData] = []

            for course in courses {
                let assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                    try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
                }
                newGroups.append(.init(course: course, assignments: assignments))
            }

            MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: newGroups)
        } catch {
            // [INFO] 暂时不处理错误
        }
    }
}
