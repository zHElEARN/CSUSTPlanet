//
//  ElectricityRecordCleaner.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/20.
//

import OSLog
import Sentry
import SwiftData

@ModelActor
actor ElectricityRecordCleaner {
    func cleanUpDuplicateRecords() async {
        Logger.electricityRecordCleaner.info("开始执行电量记录去重清理任务...")
        do {
            // 获取所有的宿舍数据
            let fetchDescriptor = FetchDescriptor<Dorm>()
            let dorms = try modelContext.fetch(fetchDescriptor)
            var deleteCount = 0

            for dorm in dorms {
                // 如果该宿舍没有记录，或只有1条记录，直接跳过
                guard let records = dorm.records, records.count > 1 else { continue }

                // 必须先按时间升序排序（从旧到新）
                let sortedRecords = records.sorted { $0.date < $1.date }
                var previousRecord: ElectricityRecord? = nil

                for record in sortedRecords {
                    if let prev = previousRecord {
                        // 判断当前记录与上一条记录的电量是否相等
                        if record.electricity == prev.electricity {
                            // 连续且电量相同，删除当前这条（保留最早的 prev）
                            modelContext.delete(record)
                            deleteCount += 1
                        } else {
                            // 电量发生变化（不连续），将 previousRecord 更新为当前这条
                            previousRecord = record
                        }
                    } else {
                        // 序列的第一条记录，直接赋值
                        previousRecord = record
                    }
                }
            }

            // 检查是否有修改并保存
            if modelContext.hasChanges {
                try modelContext.save()
                Logger.electricityRecordCleaner.info("电量记录去重完成，共清理了 \(deleteCount) 条重复数据。")
            } else {
                Logger.electricityRecordCleaner.info("没有发现需要清理的连续重复记录。")
            }

        } catch {
            SentrySDK.capture(error: error)
            Logger.electricityRecordCleaner.error("清理重复电量记录时发生错误: \(error.localizedDescription)")
        }
    }
}
