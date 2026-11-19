//
//  CourseWidgetHeaderView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import SwiftUI
import WidgetKit

struct CourseWidgetHeaderView: View {
    let family: WidgetFamily
    let title: String
    let date: Date
    let data: CourseScheduleData
    let semesterStatus: SemesterStatus
    let scheduleName: String?

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            if family != .systemSmall {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(scheduleName ?? data.semester ?? "默认学期")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Text("周\(ScheduleUtils.dayOfWeek(of: date).chineseShortString)")
                .font(.system(size: 14))
                .foregroundStyle(.red)

            Spacer()

            switch semesterStatus {
            case .beforeSemester:
                Text(CourseSchedulePresentation.semesterNotStartedText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            case .afterSemester:
                Text(CourseSchedulePresentation.semesterEndedText)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            case .inSemester(let week):
                Text("第 \(week) 周")
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
            }
        }
    }
}
