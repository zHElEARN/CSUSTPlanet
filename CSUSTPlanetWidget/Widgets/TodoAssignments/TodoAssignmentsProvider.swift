//
//  TodoAssignmentsProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import OSLog
import WidgetKit

struct TodoAssignmentsProvider: TimelineProvider {
    private let refreshEntryCount = 12

    func placeholder(in context: Context) -> TodoAssignmentsEntry {
        .mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoAssignmentsEntry) -> Void) {
        if context.isPreview {
            completion(.mockEntry())
        } else if let cache = MMKVHelper.TodoAssignments.cache {
            completion(.init(date: .now, data: cache.value, lastUpdated: cache.cachedAt))
        } else {
            completion(.init(date: .now, data: nil, lastUpdated: nil))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoAssignmentsEntry>) -> Void) {
        Task {
            let isAutoRefresh = MMKVHelper.WidgetSettings.TodoAssignments.isAutoRefresh
            let refreshInterval = MMKVHelper.WidgetSettings.TodoAssignments.refreshFrequency  // hours

            let policy: TimelineReloadPolicy = isAutoRefresh ? .after(.now.addingTimeInterval(Double(refreshInterval) * 3600)) : .never

            if isAutoRefresh {
                if let cache = MMKVHelper.TodoAssignments.cache, cache.cachedAt.addingTimeInterval(30 * 60) < .now {
                    await RefreshTodoAssignmentsTimelineIntent.update()
                } else if MMKVHelper.TodoAssignments.cache == nil {
                    await RefreshTodoAssignmentsTimelineIntent.update()
                }
            }

            guard let cache = MMKVHelper.TodoAssignments.cache else {
                completion(Timeline(entries: [TodoAssignmentsEntry(date: .now, data: nil, lastUpdated: nil)], policy: policy))
                return
            }

            completion(Timeline(entries: [TodoAssignmentsEntry(date: .now, data: cache.value, lastUpdated: cache.cachedAt)], policy: policy))
        }
    }
}
