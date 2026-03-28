//
//  CourseOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class CourseOverviewViewModel {
    enum CourseDisplayState {
        case loading
        case beforeSemester(days: Int?)
        case inSemester(courses: [(course: CourseDisplayInfo, isCurrent: Bool)])
        case afterSemester
    }

    private var courseScheduleData: Cached<CourseScheduleData>?

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
            let courses = CourseScheduleUtil.getUnfinishedCourses(
                semesterStartDate: data.semesterStartDate,
                now: .now,
                courses: data.courses
            )
            return .inSemester(courses: courses)
        }
    }

    var semesterInfoText: String {
        guard let semester = courseScheduleData?.value.semester else { return "默认学期" }
        return semester
    }

    func onAppear() {
        courseScheduleData = MMKVHelper.shared.courseScheduleCache
    }

    func formatCourseTime(_ startSection: Int, _ endSection: Int) -> String {
        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0 && startIndex < CourseScheduleUtil.sectionTimeString.count,
            endIndex >= 0 && endIndex < CourseScheduleUtil.sectionTimeString.count
        else {
            return "时间未知"
        }

        return "\(CourseScheduleUtil.sectionTimeString[startIndex].0) - \(CourseScheduleUtil.sectionTimeString[endIndex].1)"
    }
}
