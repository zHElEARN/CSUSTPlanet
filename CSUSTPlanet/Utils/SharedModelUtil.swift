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

enum ContainerLoadState {
    case normal
    case recoveredAfterWipe
    case fatalError
}

enum SharedModelUtil {
    static let currentDatabaseVersion = 3

    static var containerLoadState: ContainerLoadState = .normal

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

            wipeSwiftDataStorage()

            do {
                // 再一次在清除旧的文件的基础上初始化数据库
                let recoveredContainer = try ModelContainer(
                    for: schema,
                    migrationPlan: DormMigrationPlan.self,
                    configurations: [config]
                )
                Logger.sharedModel.warning("清空本地受损数据后，尝试恢复ModelContainer成功")
                containerLoadState = .recoveredAfterWipe
                return recoveredContainer
            } catch {
                Logger.sharedModel.error("清理旧的数据库文件后再次初始化依然失败: \(error)")
                SentrySDK.capture(error: error)

                // 彻底失败保底使用内存数据库
                containerLoadState = .fatalError
                let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                // 这里强制解包要是崩溃就无解了
                return try! ModelContainer(for: schema, configurations: [fallbackConfig])
            }
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

    /// 物理删除SwiftData底层产生的SQLite相关文件
    private static func wipeSwiftDataStorage() {
        guard let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupID) else {
            Logger.sharedModel.error("无法获取 AppGroup 路径")
            return
        }

        let applicationSupportURL = groupURL.appendingPathComponent("Library/Application Support")

        do {
            let files = try FileManager.default.contentsOfDirectory(at: applicationSupportURL, includingPropertiesForKeys: nil)
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.hasPrefix("default.store") || fileName == "default_ckAssets" {
                    try FileManager.default.removeItem(at: file)
                    Logger.sharedModel.info("清理受损的数据库实体或目录: \(fileName)")
                }
            }

            // 重置业务迁移版本号
            MMKVHelper.shared.databaseVersion = 0

        } catch {
            Logger.sharedModel.error("尝试清理底层数据库文件时发生错误: \(error)")
        }
    }
}
