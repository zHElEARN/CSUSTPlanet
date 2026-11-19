//
//  CourseWidgetBeforeSemesterView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/2/25.
//

import SwiftUI

struct CourseWidgetBeforeSemesterView: View {
    let date: Date
    let daysUntilStart: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(CourseSchedulePresentation.semesterNotStartedText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            if daysUntilStart > CourseSchedulePresentation.semesterStartThreshold {
                Text(CourseSchedulePresentation.holidayMessage(for: date))
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            } else {
                Text(CourseSchedulePresentation.semesterCountdownText(days: daysUntilStart))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}
