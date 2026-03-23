//
//  TodoHomeworkViewModel.swift
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

    var isInitial = true

    init() {
        guard let data = MMKVHelper.TodoAssignments.cache else { return }
        applyData(data)
    }

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
}
