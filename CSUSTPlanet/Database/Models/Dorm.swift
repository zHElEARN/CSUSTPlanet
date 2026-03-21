//
//  Dorm.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import Foundation
import GRDB

struct DormGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable {
    static let databaseTableName = "dorms"

    var id: Int64?
    var room: String
    var buildingID: String
    var buildingName: String
    var campusID: String
    var campusName: String
    var isFavorite: Bool
    var lastFetchDate: Date?
    var lastFetchElectricity: Double?
    var scheduleHour: Int?
    var scheduleMinute: Int?

    var scheduleEnabled: Bool { return scheduleHour != nil && scheduleMinute != nil }

    enum Columns: String, ColumnExpression {
        case id, room, buildingID, buildingName, campusID, campusName
        case isFavorite
        case lastFetchDate, lastFetchElectricity
        case scheduleHour, scheduleMinute
    }

    static let records = hasMany(ElectricityRecordGRDB.self)
}
