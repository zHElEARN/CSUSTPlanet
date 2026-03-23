//
//  AvailableClassroomViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/8.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
final class AvailableClassroomViewModel {
    var availableClassrooms: [String]? = nil
    var searchText: String = ""

    var filteredAvailableClassrooms: [String]? {
        guard let classrooms = availableClassrooms else { return nil }
        if searchText.isEmpty {
            return classrooms
        } else {
            return classrooms.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var errorToast: ToastState = .errorTitle
    var isLoadingClassrooms = false

    var selectedCampus: CampusCardHelper.Campus = .jinpenling
    var selectedWeek: Int = 1
    var selectedDayOfWeek: EduHelper.DayOfWeek = .monday
    var selectedSection: Int = 1

    func queryAvailableClassrooms() async {
        guard !isLoadingClassrooms else { return }
        isLoadingClassrooms = true
        defer { isLoadingClassrooms = false }

        do {
            availableClassrooms = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getAvailableClassrooms(
                    campus: self.selectedCampus,
                    week: self.selectedWeek,
                    dayOfWeek: self.selectedDayOfWeek,
                    section: self.selectedSection
                )
            }
            .sorted()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
