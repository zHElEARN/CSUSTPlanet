//
//  CourseSchedule.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import Foundation
import SwiftUI

enum CourseDisplaySource: Codable, Hashable {
    case official
    case custom(UUID)
}

struct CourseDisplayInfo: Identifiable, Codable {
    var id = UUID()
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let source: CourseDisplaySource

    init(
        course: EduHelper.Course,
        session: EduHelper.ScheduleSession,
        source: CourseDisplaySource = .official
    ) {
        self.course = course
        self.session = session
        self.source = source
    }
}

struct CourseScheduleData: Codable {
    var semester: String?
    var semesterStartDate: Date
    var officialCourses: [EduHelper.Course]?
    var courses: [EduHelper.Course]

    init(
        semester: String?,
        semesterStartDate: Date,
        officialCourses: [EduHelper.Course]? = nil,
        courses: [EduHelper.Course]
    ) {
        self.semester = semester
        self.semesterStartDate = semesterStartDate
        self.officialCourses = officialCourses
        self.courses = courses
    }
}

struct CourseScheduleCustomCourse: Identifiable, Codable, Hashable {
    var id: UUID
    var course: EduHelper.Course

    init(id: UUID = UUID(), course: EduHelper.Course) {
        self.id = id
        self.course = course
    }
}

struct CourseScheduleCustomization: Codable, Equatable {
    var hiddenOfficialCourseNames: Set<String>
    var customCourses: [CourseScheduleCustomCourse]

    init(
        hiddenOfficialCourseNames: Set<String> = [],
        customCourses: [CourseScheduleCustomCourse] = []
    ) {
        self.hiddenOfficialCourseNames = hiddenOfficialCourseNames
        self.customCourses = customCourses
    }
}

enum CourseScheduleComposer {
    static func compose(
        officialCourses: [EduHelper.Course],
        customization: CourseScheduleCustomization
    ) -> [EduHelper.Course] {
        let visibleOfficialCourses = officialCourses.filter {
            !customization.hiddenOfficialCourseNames.contains($0.courseName)
        }

        return visibleOfficialCourses + customization.customCourses.map(\.course)
    }
}
