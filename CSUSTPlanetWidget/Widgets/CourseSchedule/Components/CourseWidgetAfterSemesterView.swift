//
//  CourseWidgetAfterSemesterView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/2/25.
//

import SwiftUI

struct CourseWidgetAfterSemesterView: View {
    var body: some View {
        Text(CourseSchedulePresentation.semesterEndedText)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.primary)
    }
}
