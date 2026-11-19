//
//  ElectricityRecord.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import Foundation
import GRDB

struct ElectricityRecordGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable {
    static let databaseTableName = "electricity_records"

    var id: Int64?
    var electricity: Double
    var date: Date
    var dormID: Int64

    var reading: ElectricityRecord {
        ElectricityRecord(date: date, electricity: electricity)
    }

    enum Columns: String, ColumnExpression {
        case id, electricity, date, dormID
    }

    static let dorm = belongsTo(DormGRDB.self)
}
