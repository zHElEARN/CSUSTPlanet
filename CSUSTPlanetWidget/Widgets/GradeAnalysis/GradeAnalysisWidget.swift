//
//  GradeAnalysisWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import CSUSTKit
import Charts
import Foundation
import OSLog
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Widget Configuration

struct GradeAnalysisWidget: Widget {
    let kind: String = "GradeAnalysisWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: GradeAnalysisAppIntent.self, provider: GradeAnalysisProvider()) { entry in
            GradeAnalysisEntryView(entry: entry)
        }
        .configurationDisplayName("成绩分析")
        .description("查看你的成绩分析和统计信息")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Small - 空", as: .systemSmall, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.init(date: .now, configuration: .init(), data: nil, lastUpdated: nil)
}

#Preview("Medium - 空", as: .systemMedium, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.init(date: .now, configuration: .init(), data: nil, lastUpdated: nil)
}

#Preview("Large - 空", as: .systemLarge, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.init(date: .now, configuration: .init(), data: nil, lastUpdated: nil)
}

#Preview("Small - 默认", as: .systemSmall, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry()
}

#Preview("Medium - 学期GPA", as: .systemMedium, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry(configuration: .mockIntent(chartType: .semesterGPA))
}

#Preview("Medium - GPA分布", as: .systemMedium, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry(configuration: .mockIntent(chartType: .gpaDistribution))
}

#Preview("Medium - 学期平均成绩", as: .systemMedium, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry(configuration: .mockIntent(chartType: .semesterAverage))
}

#Preview("Large - 学期GPA", as: .systemLarge, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry(configuration: .mockIntent(chartType: .semesterGPA))
}

#Preview("Large - GPA分布", as: .systemLarge, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry(configuration: .mockIntent(chartType: .gpaDistribution))
}

#Preview("Large - 学期平均成绩", as: .systemLarge, widget: { GradeAnalysisWidget() }) {
    GradeAnalysisEntry.mockEntry(configuration: .mockIntent(chartType: .semesterAverage))
}
