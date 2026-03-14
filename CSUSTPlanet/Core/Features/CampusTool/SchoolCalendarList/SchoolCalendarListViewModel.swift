//
//  SchoolCalendarListViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import Alamofire
import Foundation
import Observation

struct SchoolCalendar: Codable, Identifiable {
    var id: String { semester }

    let semester: String
    let title: String
    let subtitle: String
}

@MainActor
@Observable
class SchoolCalendarListViewModel {
    var schoolCalendars: [SchoolCalendar] = []
    var isShowingError: Bool = false
    var errorMessage: String = ""
    var isLoading: Bool = false

    func loadSchoolCalendars() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            do {
                schoolCalendars = try (await AF.request("\(Constants.backendHost)/static/school_calendar/list.json").serializingDecodable([SchoolCalendar].self).value).sorted { $0.semester > $1.semester }
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
