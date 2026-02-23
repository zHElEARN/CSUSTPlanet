//
//  TodayCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/23.
//

import SwiftData
import SwiftUI
import WidgetKit

struct TodayCoursesWidget: Widget {
    let kind: String = "TodayCoursesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TodayCoursesIntent.self, provider: TodayCoursesProvider()) { entry in
            TodayCoursesEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("今日课程")
        .description("显示今天的课程安排")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry
}

#Preview(as: .systemMedium, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry
}

#Preview(as: .systemLarge, widget: { TodayCoursesWidget() }) {
    TodayCoursesEntry.mockEntry
}
