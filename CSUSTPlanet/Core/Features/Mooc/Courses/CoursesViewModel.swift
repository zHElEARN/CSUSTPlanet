//
//  CoursesViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
class CoursesViewModel {
    var courses: [MoocHelper.Course] = []
    var searchText: String = ""

    var isShowingError = false
    var errorMessage = ""

    var isLoading = false

    var filteredCourses: [MoocHelper.Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) || course.teacher.localizedCaseInsensitiveContains(searchText) || course.department.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    func task() async {
        loadCourses()
    }

    func loadCourses() {
        guard let moocHelper = AuthManager.shared.moocHelper else { return }
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            do {
                courses = try await moocHelper.getCourses()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
