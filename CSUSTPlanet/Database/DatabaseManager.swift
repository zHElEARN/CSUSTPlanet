//
//  DatabaseManager.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import Foundation
import GRDB
import OSLog
import Sentry

final class DatabaseManager {
    static let shared = DatabaseManager()

    private(set) var pool: DatabasePool?

    private(set) var hasFatalError = false
    private(set) var fatalErrorMessage: String = ""

    private init() {
        do {
            var configuration = Configuration()
            configuration.foreignKeysEnabled = true
            configuration.busyMode = .timeout(5)
            configuration.label = "CSUSTPlanet.GRDB"

            let databasePool = try DatabasePool(path: Constants.grdbDatabaseURL.path, configuration: configuration)
            try Self.migrator.migrate(databasePool)
            self.pool = databasePool
        } catch {
            SentrySDK.capture(error: error)
            self.pool = nil
            self.hasFatalError = true
            self.fatalErrorMessage = "数据库初始化失败：\(error.localizedDescription)"
        }
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_dorm_and_electricity_record") { db in
            try db.create(table: DormGRDB.databaseTableName) { t in
                t.autoIncrementedPrimaryKey(DormGRDB.Columns.id.name)
                t.column(DormGRDB.Columns.room.name, .text).notNull()
                t.column(DormGRDB.Columns.buildingID.name, .text).notNull()
                t.column(DormGRDB.Columns.buildingName.name, .text).notNull()
                t.column(DormGRDB.Columns.campusID.name, .text).notNull()
                t.column(DormGRDB.Columns.campusName.name, .text).notNull()
                t.column(DormGRDB.Columns.isFavorite.name, .boolean).notNull().defaults(to: false)
                t.column(DormGRDB.Columns.lastFetchDate.name, .datetime)
                t.column(DormGRDB.Columns.lastFetchElectricity.name, .double)
                t.column(DormGRDB.Columns.scheduleHour.name, .integer)
                t.column(DormGRDB.Columns.scheduleMinute.name, .integer)
            }

            try db.create(index: "idx_dorm_isFavorite", on: DormGRDB.databaseTableName, columns: [DormGRDB.Columns.isFavorite.name])

            try db.create(table: ElectricityRecordGRDB.databaseTableName) { t in
                t.autoIncrementedPrimaryKey(ElectricityRecordGRDB.Columns.id.name)
                t.column(ElectricityRecordGRDB.Columns.electricity.name, .double).notNull()
                t.column(ElectricityRecordGRDB.Columns.date.name, .datetime).notNull()
                t.column(ElectricityRecordGRDB.Columns.dormID.name, .integer).notNull().references(DormGRDB.databaseTableName, onDelete: .cascade)
            }

            try db.create(index: "idx_electricity_record_dormID_date", on: ElectricityRecordGRDB.databaseTableName, columns: [ElectricityRecordGRDB.Columns.dormID.name, ElectricityRecordGRDB.Columns.date.name])
        }

        return migrator
    }
}
