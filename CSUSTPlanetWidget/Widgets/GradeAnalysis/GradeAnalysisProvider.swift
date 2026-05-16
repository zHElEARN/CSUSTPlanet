//
//  GradeAnalysisProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import Foundation
import OSLog
import WidgetKit

struct GradeAnalysisProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GradeAnalysisEntry {
        .mockEntry()
    }

    func snapshot(for configuration: GradeAnalysisAppIntent, in context: Context) async -> GradeAnalysisEntry {
        if context.isPreview {
            return .mockEntry(configuration: configuration)
        } else if let gradeAnalysis = MMKVHelper.CourseGrades.cache {
            return .init(date: .now, configuration: configuration, data: GradeAnalysisData.fromCourseGrades(gradeAnalysis.value), lastUpdated: gradeAnalysis.cachedAt)
        } else {
            return .mockEntry(configuration: configuration)
        }
    }

    func timeline(for configuration: GradeAnalysisAppIntent, in context: Context) async -> Timeline<GradeAnalysisEntry> {
        let isAutoRefresh = MMKVHelper.WidgetSettings.GradeAnalysis.isAutoRefresh
        let refreshInterval = MMKVHelper.WidgetSettings.GradeAnalysis.refreshFrequency  // hours

        let policy: TimelineReloadPolicy = isAutoRefresh ? .after(.now.addingTimeInterval(Double(refreshInterval) * 3600)) : .never

        if isAutoRefresh {
            if let cache = MMKVHelper.CourseGrades.cache, cache.cachedAt.addingTimeInterval(30 * 60) < .now {
                await RefreshGradeAnalysisTimelineIntent.update()
            } else if MMKVHelper.CourseGrades.cache == nil {
                await RefreshGradeAnalysisTimelineIntent.update()
            }
        }

        guard let cache = MMKVHelper.CourseGrades.cache else {
            return Timeline(entries: [GradeAnalysisEntry(date: .now, configuration: configuration, data: nil, lastUpdated: nil)], policy: policy)
        }

        return Timeline(
            entries: [
                GradeAnalysisEntry(
                    date: .now,
                    configuration: configuration,
                    data: GradeAnalysisData.fromCourseGrades(cache.value),
                    lastUpdated: cache.cachedAt
                )
            ],
            policy: policy
        )
    }
}
