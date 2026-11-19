//
//  CourseScheduleScrollTable.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleScrollTable: View {
    let semesterStartDate: Date
    let weeklyCourses: [Int: [CourseOccurrence]]
    let courseColors: [String: Color]

    @Binding var currentWeek: Int
    let weekCount: Int
    @Binding var isCourseDetailInspectorPresented: Bool
    @Binding var selectedCourseInfo: CourseOccurrence?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(1...weekCount, id: \.self) { week in
                    CourseScheduleTable(
                        semesterStartDate: semesterStartDate,
                        targetWeek: week,
                        weeklyCourses: weeklyCourses,
                        courseColors: courseColors,
                        isCourseDetailInspectorPresented: $isCourseDetailInspectorPresented,
                        selectedCourseInfo: $selectedCourseInfo
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollPosition(
            id: Binding<Int?>(
                get: { currentWeek },
                set: { if let newWeek = $0 { currentWeek = newWeek } }
            )
        )
    }
}
