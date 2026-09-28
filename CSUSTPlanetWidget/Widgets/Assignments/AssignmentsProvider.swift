//
//  AssignmentsProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import OSLog
import WidgetKit

struct AssignmentsProvider: TimelineProvider {
    private let refreshEntryCount = 12

    func placeholder(in context: Context) -> AssignmentsEntry {
        .mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (AssignmentsEntry) -> Void) {
        if context.isPreview {
            completion(.mockEntry())
        } else if let cache = MMKVHelper.Assignments.cache {
            completion(.init(date: .now, data: cache.value, lastUpdated: cache.cachedAt))
        } else {
            completion(.init(date: .now, data: nil, lastUpdated: nil))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AssignmentsEntry>) -> Void) {
        Task {
            TrackHelper.shared.views(path: ["Widget", "TodoAssignmentsWidget", "Timeline"])

            let isAutoRefresh = MMKVHelper.WidgetSettings.Assignments.isAutoRefresh
            let refreshInterval = MMKVHelper.WidgetSettings.Assignments.refreshFrequency  // hours

            let policy: TimelineReloadPolicy = isAutoRefresh ? .after(.now.addingTimeInterval(Double(refreshInterval) * 3600)) : .never

            if isAutoRefresh {
                if let cache = MMKVHelper.Assignments.cache, cache.cachedAt.addingTimeInterval(30 * 60) < .now {
                    await RefreshAssignmentsTimelineIntent.update()
                } else if MMKVHelper.Assignments.cache == nil {
                    await RefreshAssignmentsTimelineIntent.update()
                }
            }

            guard let cache = MMKVHelper.Assignments.cache else {
                completion(Timeline(entries: [AssignmentsEntry(date: .now, data: nil, lastUpdated: nil)], policy: policy))
                return
            }

            completion(Timeline(entries: [AssignmentsEntry(date: .now, data: cache.value, lastUpdated: cache.cachedAt)], policy: policy))
        }
    }
}
