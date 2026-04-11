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

        let entry = TodoAssignmentsEntry(
            date: .now,
            data: finalData?.value,
            lastUpdated: finalData?.cachedAt
        )

        Logger.todoAssignmentsWidget.info("待提交作业 timeline 生成完成")
        completion(Timeline(entries: [entry], policy: .never))
    }
}
