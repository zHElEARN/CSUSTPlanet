//
//  AvailableClassroomView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/8.
//

import CSUSTKit
import SwiftUI

struct AvailableClassroomView: View {
    @State private var availableClassrooms: [String]?

    @State private var isLoadingClassrooms: Bool = false

    @State private var errorToast: ToastState = .errorTitle

    @State private var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @State private var selectedWeek: Int = 1
    @State private var selectedDayOfWeek: EduHelper.DayOfWeek = .monday
    @State private var selectedSection: Int = 1

    var body: some View {
        AvailableClassroomContent(
            availableClassrooms: availableClassrooms,
            isLoading: isLoadingClassrooms,
            selectedCampus: $selectedCampus,
            selectedWeek: $selectedWeek,
            selectedDayOfWeek: $selectedDayOfWeek,
            selectedSection: $selectedSection,
            errorToast: $errorToast,
            onQuery: queryAvailableClassrooms
        )
    }

    // MARK: - Methods

    private func queryAvailableClassrooms() async {
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
