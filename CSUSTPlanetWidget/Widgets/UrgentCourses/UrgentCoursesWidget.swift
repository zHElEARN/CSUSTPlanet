//
//  UrgentCoursesWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import CSUSTKit
import Foundation
import SwiftUI
import WidgetKit

struct UrgentCoursesWidget: Widget {
    let kind: String = "UrgentCoursesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UrgentCoursesProvider()) { entry in
            UrgentCoursesEntryView(entry: entry)
        }
        .configurationDisplayName("待提交作业")
        .description("查看网络课程平台的待提交作业课程")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall, widget: { UrgentCoursesWidget() }) {
    UrgentCoursesEntry.mockEntry()
}
