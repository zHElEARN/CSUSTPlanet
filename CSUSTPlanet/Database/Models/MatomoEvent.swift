//
//  MatomoEvent.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/5/15.
//

import Foundation
import GRDB

struct MatomoEventGRDB: Codable, FetchableRecord, MutablePersistableRecord, TableRecord, Identifiable, Equatable, Hashable {
    static let databaseTableName = "matomo_events"

    var id: UUID
    var payload: Data
    var createdAt: Date

    enum Columns: String, ColumnExpression {
        case id, payload, createdAt
    }
}
