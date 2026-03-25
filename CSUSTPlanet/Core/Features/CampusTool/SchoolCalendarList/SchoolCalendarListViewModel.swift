//
//  SchoolCalendarListViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import Foundation
import Observation

typealias SchoolCalendar = PlanetService.Config.SchoolCalendar

@MainActor
@Observable
class SchoolCalendarListViewModel {
    var schoolCalendars: [SchoolCalendar] = []
    var errorToast: ToastState = .errorTitle

    var isLoadingCalendars: Bool = false

    func loadSchoolCalendars() async {
        guard !isLoadingCalendars else { return }
        isLoadingCalendars = true
        defer { isLoadingCalendars = false }

        do {
            schoolCalendars = try await PlanetService.Config.semesterCalendars().sorted { $0.semesterCode > $1.semesterCode }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
