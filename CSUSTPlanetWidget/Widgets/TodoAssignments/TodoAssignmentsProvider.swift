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
        Logger.todoAssignmentsWidget.info("Timeline 开始读取待提交作业缓存数据")

        var finalData: Cached<[TodoAssignmentsData]>? = nil

        if let cache = MMKVHelper.TodoAssignments.cache {
            Logger.todoAssignmentsWidget.info("成功从缓存获取待提交作业数据，共 \(cache.value.count) 门课程")
            finalData = cache
        } else {
            Logger.todoAssignmentsWidget.info("缓存中无数据，将显示空视图")
        }

        let now = Date.now
        let refreshDates = timelineRefreshDates(from: now, count: refreshEntryCount)
        let entries = refreshDates.map { refreshDate in
            TodoAssignmentsEntry(
                date: refreshDate,
                data: finalData?.value,
                lastUpdated: finalData?.cachedAt
            )
        }

        Logger.todoAssignmentsWidget.info("待提交作业 timeline 生成完成，共 \(entries.count) 个时间点")
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func timelineRefreshDates(from date: Date, count: Int) -> [Date] {
        guard count > 0 else { return [date] }

        let calendar = Calendar.current
        let nextHour =
            calendar.nextDate(
                after: date,
                matching: DateComponents(minute: 0, second: 0),
                matchingPolicy: .nextTime
            ) ?? date.addingTimeInterval(3600)

        return [date]
            + (0..<count).compactMap { offset in
                calendar.date(byAdding: .hour, value: offset, to: nextHour)
            }
    }
}
