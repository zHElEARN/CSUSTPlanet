//
//  RefreshTodoAssignmentsTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/3/27.
//

import AppIntents
import WidgetKit

struct RefreshTodoAssignmentsTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新待提交作业时间线"
    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
