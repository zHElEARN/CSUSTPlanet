//
//  TodoHomeworkViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import SwiftUI

struct TodoAssignmentCourseGroup: Identifiable, Hashable {
    let course: MoocHelper.Course
    let allAssignments: [MoocHelper.Assignment]
    let unexpiredAssignments: [MoocHelper.Assignment]

    var id: String { course.id }
}

@MainActor
@Observable
final class TodoAssignmentsViewModel {
    var courseGroups: [TodoAssignmentCourseGroup] = []
    var expandedCourseIDs: Set<String> = []
    var showAllAssignmentsCourseIDs: Set<String> = []
    var unexpiredAssignmentsCount = 0

    var isLoadingAssignments = false

    var errorToast: ToastState = .errorTitle

    var isInitial = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadTodoAssignments()
    }

    func loadTodoAssignments() async {
        guard !isLoadingAssignments else { return }
        isLoadingAssignments = true
        defer { isLoadingAssignments = false }

        do {
            let courses = try await AuthManager.shared.moocHelper.getCoursesWithPendingAssignments()
            var newGroups: [TodoAssignmentCourseGroup] = []

            for course in courses {
                let assignments = try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
                let unexpiredAssignments = assignments.filter { $0.deadline >= .now }
                newGroups.append(
                    TodoAssignmentCourseGroup(
                        course: course,
                        allAssignments: assignments,
                        unexpiredAssignments: unexpiredAssignments
                    )
                )
            }

            courseGroups = newGroups
            expandedCourseIDs = Set(newGroups.map(\.id))
            unexpiredAssignmentsCount = newGroups.reduce(0) { partialResult, group in
                partialResult + group.unexpiredAssignments.count
            }
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

    func displayedAssignments(for group: TodoAssignmentCourseGroup) -> [MoocHelper.Assignment] {
        if isShowingAllAssignments(courseID: group.id) {
            return group.allAssignments
        }

        return group.unexpiredAssignments
    }
}
