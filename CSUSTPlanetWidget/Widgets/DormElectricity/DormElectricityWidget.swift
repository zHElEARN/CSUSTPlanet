//
//  DormElectricityWidget.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import CSUSTKit
import Charts
import OSLog
import SwiftData
import SwiftUI
import WidgetKit

struct DormElectricityWidget: Widget {
    let kind = "DormElectricityWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: DormElectricityAppIntent.self, provider: DormElectricityProvider()) { entry in
            DormElectricityEntryView(entry: entry)
                .modelContainer(SharedModelUtil.container)
        }
        .configurationDisplayName("宿舍电量")
        .description("查询宿舍电量使用情况")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview("Small - 未配置", as: .systemSmall, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(date: .now, configuration: DormElectricityAppIntent(), records: [], lastFetchDate: nil)
}

#Preview("Medium - 未配置", as: .systemMedium, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(date: .now, configuration: DormElectricityAppIntent(), records: [], lastFetchDate: nil)
}

#Preview("Large - 未配置", as: .systemLarge, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(date: .now, configuration: DormElectricityAppIntent(), records: [], lastFetchDate: nil)
}

#Preview("Small - 半完整", as: .systemSmall, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(date: .now, configuration: .mockIntent, records: [], lastFetchDate: nil)
}

#Preview("Medium - 半完整", as: .systemMedium, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(date: .now, configuration: .mockIntent, records: [], lastFetchDate: nil)
}

#Preview("Large - 半完整", as: .systemLarge, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(date: .now, configuration: .mockIntent, records: [], lastFetchDate: nil)
}

#Preview("Small - 完整", as: .systemSmall, widget: { DormElectricityWidget() }) {
    DormElectricityEntry.mockEntry
}

#Preview("Medium - 完整", as: .systemMedium, widget: { DormElectricityWidget() }) {
    DormElectricityEntry.mockEntry
}

#Preview("Large - 完整", as: .systemLarge, widget: { DormElectricityWidget() }) {
    DormElectricityEntry.mockEntry
}

#Preview("Medium - 完整（单电量）", as: .systemMedium, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(
        date: .now,
        configuration: .mockIntent,
        records: [.init(electricity: 30, date: .now.addingTimeInterval(-86400))],
        lastFetchDate: .now
    )
}

#Preview("Large - 完整（单电量）", as: .systemLarge, widget: { DormElectricityWidget() }) {
    DormElectricityEntry(
        date: .now,
        configuration: .mockIntent,
        records: [.init(electricity: 30, date: .now.addingTimeInterval(-86400))],
        lastFetchDate: .now
    )
}
