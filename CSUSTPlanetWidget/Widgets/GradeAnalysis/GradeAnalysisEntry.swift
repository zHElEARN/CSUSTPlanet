//
//  GradeAnalysisEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import WidgetKit

struct GradeAnalysisEntry: TimelineEntry {
    let date: Date
    let configuration: GradeAnalysisAppIntent
    let data: GradeAnalysisData?
    let lastUpdated: Date?

    static func mockEntry(configuration: GradeAnalysisAppIntent? = nil) -> GradeAnalysisEntry {
        return GradeAnalysisEntry(
            date: .now,
            configuration: configuration ?? GradeAnalysisAppIntent(),
            data: GradeAnalysisData(
                totalCourses: 23,
                totalHours: 740,
                totalCredits: 45.5,
                overallAverageGrade: 85.35,
                overallGPA: 3.26,
                weightedAverageGrade: 83.58,
                gradePointDistribution: [
                    (gradePoint: 4.0, count: 8),
                    (gradePoint: 3.7, count: 7),
                    (gradePoint: 3.3, count: 2),
                    (gradePoint: 3.0, count: 2),
                    (gradePoint: 2.7, count: 3),
                    (gradePoint: 2.0, count: 1),
                    (gradePoint: 1.7, count: 1),
                    (gradePoint: 1.3, count: 1),
                    (gradePoint: 1.0, count: 1),
                    (gradePoint: 0.0, count: 1),
                ],
                semesterAverageGrades: [
                    (semester: "2024-2025-1", average: 88.4),
                    (semester: "2024-2025-2", average: 82.6),
                ],
                semesterGPAs: [
                    (semester: "2024-2025-1", gpa: 3.44),
                    (semester: "2024-2025-2", gpa: 3.09),
                ],
            ),
            lastUpdated: .now.addingTimeInterval(-10)
        )
    }
}
