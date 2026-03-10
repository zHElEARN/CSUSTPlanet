//
//  SharedModelUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import Foundation
import OSLog
import Sentry
import SwiftData

enum SharedModelUtil {
    static let currentDatabaseVersion = 3

    static var isContainerLoadFailed = false

    static let schema = Schema([
        Dorm.self,
        ElectricityRecord.self,
    ])

    static let container: ModelContainer = {
        let config = ModelConfiguration(
            isStoredInMemoryOnly: false,
            groupContainer: .identifier(Constants.appGroupID),
            cloudKitDatabase: .private(Constants.iCloudID)
        )

        Logger.sharedModel.info("正在使用 iCloud 容器：\(String(describing: config.cloudKitDatabase))")

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: DormMigrationPlan.self,
                configurations: [config]
            )
        } catch {
            Logger.sharedModel.error("首次初始化 ModelContainer 初始化失败: \(error)")
            SentrySDK.capture(error: error)
            // fatalError("ModelContainer 初始化失败: \(error)")

            isContainerLoadFailed = true
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            // 这里还需要再看如何处理强制解包，或者尝试恢复
            return try! ModelContainer(for: schema, configurations: [fallbackConfig])
        }
    }()

    @MainActor
    static let mainContext: ModelContext = container.mainContext

    static var context: ModelContext { return ModelContext(container) }

    @MainActor
    static func clearAllData() throws {
        let context = self.context
        try context.delete(model: Dorm.self)
        try context.delete(model: ElectricityRecord.self)
        try context.save()
    }

    @MainActor
    static func migrateDatabase() async {
        // 数据库挂了则不用迁移了
        guard !isContainerLoadFailed else { return }

        let currentVersion = MMKVHelper.shared.databaseVersion

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

            MMKVHelper.shared.databaseVersion = currentDatabaseVersion
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
            var recordDescriptor = FetchDescriptor<ElectricityRecord>(
                predicate: #Predicate { $0.dorm?.id == dorm.id },
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
