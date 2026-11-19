//
//  GradeDetailParams.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

import CSUSTKit

struct GradeDetailParams: Hashable {
    let semester: String
    let courseID: String
    let courseName: String
    let groupName: String
    let grade: Int
    let gradeDetailURL: String
    let studyMode: String
    let gradeIdentifier: String
    let credit: Double
    let totalHours: Double
    let gradePoint: Double
    let retakeSemester: String
    let assessmentMethod: String
    let examNature: String
    let courseAttribute: String
    let courseNature: EduHelper.CourseNature
    let courseCategory: String

    init(courseGrade: EduHelper.CourseGrade) {
        semester = courseGrade.semester
        courseID = courseGrade.courseID
        courseName = courseGrade.courseName
        groupName = courseGrade.groupName
        grade = courseGrade.grade
        gradeDetailURL = courseGrade.gradeDetailURL
        studyMode = courseGrade.studyMode
        gradeIdentifier = courseGrade.gradeIdentifier
        credit = courseGrade.credit
        totalHours = courseGrade.totalHours
        gradePoint = courseGrade.gradePoint
        retakeSemester = courseGrade.retakeSemester
        assessmentMethod = courseGrade.assessmentMethod
        examNature = courseGrade.examNature
        courseAttribute = courseGrade.courseAttribute
        courseNature = courseGrade.courseNature
        courseCategory = courseGrade.courseCategory
    }
}
