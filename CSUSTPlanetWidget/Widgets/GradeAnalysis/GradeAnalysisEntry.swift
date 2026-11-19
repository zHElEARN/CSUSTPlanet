//
//  GradeAnalysisEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import WidgetKit

struct GradeAnalysisEntry: TimelineEntry {
    let date: Date
    let configuration: GradeAnalysisAppIntent
    let data: GradeStatistics?
    let lastUpdated: Date?

    static func mockEntry(configuration: GradeAnalysisAppIntent? = nil) -> GradeAnalysisEntry {
        return GradeAnalysisEntry(
            date: .now,
            configuration: configuration ?? GradeAnalysisAppIntent(),
            data: mockStatistics,
            lastUpdated: .now.addingTimeInterval(-10)
        )
    }

    private static let mockStatistics: GradeStatistics = {
        let gradesBySemester = [
            (semester: "2024-2025-1", grades: [99, 98, 96, 95, 92, 89, 87, 86, 83, 79, 76, 75]),
            (semester: "2024-2025-2", grades: [98, 96, 93, 88, 86, 84, 70, 67, 65, 62, 59]),
        ]
        let courseGrades = gradesBySemester.flatMap { semester, grades in
            grades.enumerated().map { index, grade in
                let courseNumber = index + 1
                let credit = index.isMultiple(of: 2) ? 2.5 : 1.5
                return EduHelper.CourseGrade(
                    semester: semester,
                    courseID: "\(semester)-\(courseNumber)",
                    courseName: "示例课程 \(courseNumber)",
                    groupName: "",
                    grade: grade,
                    gradeDetailURL: "",
                    studyMode: "正常",
                    gradeIdentifier: "",
                    credit: credit,
                    totalHours: credit * 16,
                    gradePoint: GradeScale.gradePoint(forGrade: grade) ?? 0,
                    retakeSemester: "",
                    assessmentMethod: "考试",
                    examNature: "正常考试",
                    courseAttribute: "必修",
                    courseNature: .professionalCourse,
                    courseCategory: "专业课"
                )
            }
        }
        return GradeStatistics(courseGrades: courseGrades)
    }()
}
