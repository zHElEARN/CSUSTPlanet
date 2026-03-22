//
//  DormIntentQuery.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation
import GRDB

struct DormIntentQuery: EntityQuery {
    func suggestedEntities() async throws -> [DormIntentEntity] {
        guard let pool = DatabaseManager.shared.pool else { return [] }

        return try await pool.read { db in
            let dorms = try DormGRDB.order(DormGRDB.Columns.id.desc).fetchAll(db)
            return dorms.compactMap { dorm in
                guard let dormID = dorm.id else { return nil }
                return DormIntentEntity(id: dormID, room: dorm.room, buildingName: dorm.buildingName, campusName: dorm.campusName)
            }
        }
    }

    func entities(for identifiers: [String]) async throws -> [DormIntentEntity] {
        let dormIDs = identifiers.compactMap(Int64.init)
        guard !dormIDs.isEmpty else { return [] }
        guard let pool = DatabaseManager.shared.pool else { return [] }

        return try await pool.read { db in
            let dorms = try DormGRDB.filter(dormIDs.contains(DormGRDB.Columns.id)).fetchAll(db)
            return dorms.compactMap { dorm in
                guard let dormID = dorm.id else { return nil }
                return DormIntentEntity(id: dormID, room: dorm.room, buildingName: dorm.buildingName, campusName: dorm.campusName)
            }
        }
    }

    func defaultResult() async -> DormIntentEntity? {
        try? await suggestedEntities().first
    }
}
