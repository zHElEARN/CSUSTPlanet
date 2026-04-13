//
//  CourseOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class CourseOverviewViewModel {
    enum CourseDisplayState {
        case loading
        case beforeSemester(days: Int?)
        case inSemester(todayCourseState: TodayCourseState)
        case afterSemester
    }

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var courseScheduleData: Cached<CourseScheduleData>?

    init() {
        MMKVHelper.CourseSchedule.$cache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.courseScheduleData = data
            }
            .store(in: &cancellables)
    }

    var courseDisplayState: CourseDisplayState {
        guard let data = courseScheduleData?.value else { return .loading }

        let status = CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: .now)

        switch status {
        case .beforeSemester:
            let days = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: .now)
            return .beforeSemester(days: days)
        case .afterSemester:
            return .afterSemester
        case .inSemester:
            let todayCourseState = CourseScheduleUtil.getTodayCourseState(
                semesterStartDate: data.semesterStartDate,
                now: .now,
                courses: data.courses
            )
            return .inSemester(todayCourseState: todayCourseState)
        }
    }

    var semesterInfoText: String {
        guard let semester = courseScheduleData?.value.semester else { return "默认学期" }
        return semester
    }
}
