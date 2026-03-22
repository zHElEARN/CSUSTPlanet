//
//  SharedModelUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/10.
//

import OSLog
import Sentry
import SwiftData

// 只编译到App中，不在Widget中编译（Widget中没有足够的内存进行迁移）

extension SharedModelUtil {
    @MainActor
    static func migrateDatabase() async {
        // 数据库挂了则不用迁移了
        guard containerLoadState == .normal else { return }

        let currentVersion = MMKVHelper.SwiftData.databaseVersion

        guard currentVersion < currentDatabaseVersion else {
            return
        }

        Logger.sharedModel.info("需要迁移数据库: 当前版本 \(currentVersion) -> 目标版本 \(currentDatabaseVersion)")
        let context = SharedModelUtil.mainContext

        do {
            if currentVersion < 3 {
                try await migrateDataForV3(context: context)
                try context.save()

                /// 清理宿舍电量中是否有连续重复的电量记录
                let cleaner = ElectricityRecordCleaner(modelContainer: container)
                await cleaner.cleanUpDuplicateRecords()
            }

            // 未来的数据库迁移样例
            // if currentVersion < 4 {
            //     try patchDataForV4(context: context)
            // }

            // 保存所有修改
            try context.save()

            MMKVHelper.SwiftData.databaseVersion = currentDatabaseVersion
            Logger.sharedModel.info("迁移完成，当前数据库版本已更新至\(currentDatabaseVersion)")

        } catch {
            Logger.sharedModel.error("迁移失败，下次启动将重试：\(error)")
            SentrySDK.capture(error: error)
        }
    }

    @MainActor
    private static func migrateDataForV3(context: ModelContext) async throws {
        Logger.sharedModel.info("开始进行到V3版本数据库的迁移")

        let descriptor = FetchDescriptor<Dorm>()
        let dorms = try context.fetch(descriptor)

        for dorm in dorms {
            // 找出每个宿舍最新的电费记录
            let dormID = dorm.id
            var recordDescriptor = FetchDescriptor<ElectricityRecord>(
                predicate: #Predicate { $0.dorm?.id == dormID },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            recordDescriptor.fetchLimit = 1

            if let latestRecord = try context.fetch(recordDescriptor).first {
                // 补充 V1 -> V2 缺失的字段
                if dorm.lastFetchDate == nil {
                    dorm.lastFetchDate = latestRecord.date
                }
                // 补充 V2 -> V3 缺失的字段
                if dorm.lastFetchElectricity == nil {
                    dorm.lastFetchElectricity = latestRecord.electricity
                }
            }
        }
    }
}
