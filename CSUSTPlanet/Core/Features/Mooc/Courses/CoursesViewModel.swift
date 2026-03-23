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

    var errorToast: ToastState = .errorTitle

    var isLoadingCourses = false

    var isInitial = true

    var filteredCourses: [MoocHelper.Course] {
        if searchText.isEmpty {
            return courses
        } else {
            return courses.filter { course in
                course.name.localizedCaseInsensitiveContains(searchText) || course.teacher?.localizedCaseInsensitiveContains(searchText) == true || course.department?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadCourses()
    }

    func loadCourses() async {
        guard !isLoadingCourses else { return }
        isLoadingCourses = true
        defer { isLoadingCourses = false }

        do {
            courses = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCourses()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
