//
//  SchoolCalendarListView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import SwiftUI

struct SchoolCalendarListView: View {
    @State private var schoolCalendars: [SchoolCalendar] = []

    @State private var isLoadingCalendars: Bool = false

    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        SchoolCalendarListContent(
            schoolCalendars: schoolCalendars,
            isLoadingCalendars: isLoadingCalendars,
            errorToast: $errorToast,
            onQuery: loadSchoolCalendars
        )
        .task { await loadSchoolCalendars() }
    }

    // MARK: - Methods

    private func loadSchoolCalendars() async {
        guard !isLoadingCalendars else { return }
        isLoadingCalendars = true
        defer { isLoadingCalendars = false }

        do {
            schoolCalendars = try await PlanetConfigService.semesterCalendars().sorted { $0.semesterCode > $1.semesterCode }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
