//
//  CourseWidgetBeforeSemesterView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/2/25.
//

import SwiftUI

struct CourseWidgetBeforeSemesterView: View {
    let date: Date
    let data: CourseScheduleData

    var body: some View {
        VStack(spacing: 4) {
            Text("学期未开始")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            if let daysUntilStart = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: date) {
                if daysUntilStart > CourseScheduleUtil.semesterStartThreshold {
                    Text(CourseScheduleUtil.getHolidayMessage(for: date))
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text("还有 \(daysUntilStart) 天开学")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
