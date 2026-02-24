//
//  WeeklyCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/25.
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

struct WeeklyCoursesWidget: Widget {
    let kind: String = "WeeklyCoursesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeeklyCoursesProvider()) { entry in
            WeeklyCoursesEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("本周课程")
        .description("查看本周的课程安排")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    WeeklyCoursesWidget()
} timeline: {
    WeeklyCoursesEntry.mockEntry()
}
