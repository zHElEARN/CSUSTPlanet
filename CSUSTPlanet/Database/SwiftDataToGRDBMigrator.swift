//
//  SwiftDataToGRDBMigrator.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/22.
//

import Foundation
import GRDB
import OSLog
import SwiftData

struct SwiftDataToGRDBMigrator {
    private struct DormTransfer: Sendable {
        let room: String
        let buildingID: String
        let buildingName: String
        let campusID: String
        let campusName: String
        let isFavorite: Bool
        let lastFetchDate: Date?
        let lastFetchElectricity: Double?
        let scheduleHour: Int?
        let scheduleMinute: Int?
        let records: [RecordTransfer]
    }

    private struct RecordTransfer: Sendable {
        let electricity: Double
        let date: Date
    }

    @MainActor
    static func migrateIfNeeded() async {
        guard !MMKVHelper.SwiftData.hasMigratedToGRDB else { return }

        await SharedModelUtil.migrateDatabase()

        guard SharedModelUtil.containerLoadState != .fatalError else {
            Logger.sharedModel.warning("SwiftData 处于 fatalError 状态，跳过向 GRDB 的迁移")
            MMKVHelper.SwiftData.hasMigratedToGRDB = true
            return
        }

        let context = SharedModelUtil.mainContext
        guard let dbPool = DatabaseManager.shared.pool else {
            Logger.sharedModel.error("GRDB 数据库未就绪，无法进行迁移")
            return
        }

        do {
            Logger.sharedModel.info("开始将数据从 SwiftData 迁移至 GRDB...")

            let descriptor = FetchDescriptor<Dorm>()
            let swiftDataDorms = try context.fetch(descriptor)

            var tempDorms: [DormTransfer] = []
            var hasFoundFavorite = false

            for dorm in swiftDataDorms {
                let transferRecords =
                    dorm.records?.map { record in
                        RecordTransfer(electricity: record.electricity, date: record.date)
                    } ?? []

                let safeIsFavorite: Bool
                if dorm.isFavorite {
                    if !hasFoundFavorite {
                        safeIsFavorite = true
                        hasFoundFavorite = true
                    } else {
                        safeIsFavorite = false
                    }
                } else {
                    safeIsFavorite = false
                }

                let transferDorm = DormTransfer(
                    room: dorm.room,
                    buildingID: dorm.buildingID,
                    buildingName: dorm.buildingName,
                    campusID: dorm.campusID,
                    campusName: dorm.campusName,
                    isFavorite: safeIsFavorite,
                    lastFetchDate: dorm.lastFetchDate,
                    lastFetchElectricity: dorm.lastFetchElectricity,
                    scheduleHour: dorm.scheduleHour,
                    scheduleMinute: dorm.scheduleMinute,
                    records: transferRecords
                )

                tempDorms.append(transferDorm)
            }

            let finalDormsToMigrate = tempDorms

            try await dbPool.write { db in
                try ElectricityRecordGRDB.deleteAll(db)
                try DormGRDB.deleteAll(db)

                for transferDorm in finalDormsToMigrate {
                    var dormGRDB = DormGRDB(
                        id: nil,
                        room: transferDorm.room,
                        buildingID: transferDorm.buildingID,
                        buildingName: transferDorm.buildingName,
                        campusID: transferDorm.campusID,
                        campusName: transferDorm.campusName,
                        isFavorite: transferDorm.isFavorite,
                        lastFetchDate: transferDorm.lastFetchDate,
                        lastFetchElectricity: transferDorm.lastFetchElectricity,
                        scheduleHour: transferDorm.scheduleHour,
                        scheduleMinute: transferDorm.scheduleMinute
                    )

                    try dormGRDB.insert(db)

                    let newDormID = db.lastInsertedRowID

                    for transferRecord in transferDorm.records {
                        var recordGRDB = ElectricityRecordGRDB(
                            id: nil,
                            electricity: transferRecord.electricity,
                            date: transferRecord.date,
                            dormID: newDormID
                        )
                        try recordGRDB.insert(db)
                    }
                }
            }

            MMKVHelper.SwiftData.hasMigratedToGRDB = true
            Logger.sharedModel.info("SwiftData 到 GRDB 的数据迁移完成")

            do {
                try SharedModelUtil.clearAllData()
                Logger.sharedModel.info("已安全清空旧的 SwiftData 实体数据")
            } catch {
                Logger.sharedModel.error("清空 SwiftData 数据时发生错误: \(error.localizedDescription)")
            }
        } catch {
            Logger.sharedModel.error("SwiftData 到 GRDB 迁移过程中发生错误: \(error.localizedDescription)")
        }
    }
}
