//
//  UrgentCoursesViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftData
import WidgetKit

@MainActor
class UrgentCoursesViewModel: ObservableObject {
    @Published var errorMessage = ""
    @Published var warningMessage = ""
    @Published var data: Cached<UrgentCoursesData>? = nil

    @Published var isLoading = false
    @Published var isShowingError = false
    @Published var isShowingWarning = false

    var isLoaded: Bool = false

    init() {
        guard let data = MMKVHelper.shared.urgentCoursesCache else { return }
        self.data = data
    }

    func loadUrgentCourses() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            do {
                let urgentCourses = try await AuthManager.shared.moocHelper.getCourseNamesWithPendingAssignments()
                let data = Cached(cachedAt: .now, value: UrgentCoursesData.fromCourses(urgentCourses))
                self.data = data
                MMKVHelper.shared.urgentCoursesCache = data
                WidgetCenter.shared.reloadTimelines(ofKind: "UrgentCoursesWidget")
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
