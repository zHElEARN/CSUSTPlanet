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
        Logger.gradeAnalysisWidget.info("Timeline 开始读取成绩缓存数据")

        var finalData: Cached<[EduHelper.CourseGrade]>? = nil

        if let gradeAnalysis = MMKVHelper.CourseGrades.cache {
            Logger.gradeAnalysisWidget.info("成功从缓存获取成绩分析数据")
            finalData = gradeAnalysis
        } else {
            Logger.gradeAnalysisWidget.info("缓存中无数据，将显示空视图")
        }

        let entry = GradeAnalysisEntry(
            date: .now,
            configuration: configuration,
            data: GradeAnalysisData.fromCourseGrades(finalData?.value ?? []),
            lastUpdated: finalData?.cachedAt
        )

        return Timeline(entries: [entry], policy: .never)
    }
}
