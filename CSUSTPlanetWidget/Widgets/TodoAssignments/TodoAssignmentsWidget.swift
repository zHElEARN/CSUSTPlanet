//
//  TodoAssignmentsWidget.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import Foundation
import SwiftUI
import WidgetKit

struct TodoAssignmentsWidget: Widget {
    let kind: String = "TodoAssignmentsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoAssignmentsProvider()) { entry in
            TodoAssignmentsEntryView(entry: entry)
        }
        .configurationDisplayName("待提交作业")
        .description("查看课程和未截止作业的截止时间")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Small - 空数据", as: .systemSmall, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .emptyData)
}

#Preview("Small - 无未截止作业", as: .systemSmall, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .emptyAssignments)
}

#Preview("Small - 1个作业", as: .systemSmall, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(1))
}

#Preview("Small - 4个作业", as: .systemSmall, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(4))
}

#Preview("Small - 5个作业", as: .systemSmall, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(5))
}

#Preview("Medium - 空数据", as: .systemMedium, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .emptyData)
}

#Preview("Medium - 无未截止作业", as: .systemMedium, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .emptyAssignments)
}

#Preview("Medium - 1个作业", as: .systemMedium, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(1))
}

#Preview("Medium - 5个作业", as: .systemMedium, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(5))
}

#Preview("Medium - 6个作业", as: .systemMedium, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(6))
}

#Preview("Large - 空数据", as: .systemLarge, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .emptyData)
}

#Preview("Large - 无未截止作业", as: .systemLarge, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .emptyAssignments)
}

#Preview("Large - 1个作业", as: .systemLarge, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(1))
}

#Preview("Large - 3个作业", as: .systemLarge, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(3))
}

#Preview("Large - 6个作业", as: .systemLarge, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(6))
}

#Preview("Large - 7个作业", as: .systemLarge, widget: { TodoAssignmentsWidget() }) {
    TodoAssignmentsEntry.mockEntry(scenario: .assignments(7))
}
