//
//  DormIntentQuery.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation
import SwiftData

struct DormIntentQuery: EntityQuery {
    func suggestedEntities() async throws -> [DormIntentEntity] {
        let dorms = try SharedModelUtil.context.fetch(FetchDescriptor<Dorm>())
        return dorms.map { DormIntentEntity(id: $0.id, room: $0.room, buildingName: $0.buildingName, campusName: $0.campusName) }
    }

    func entities(for identifiers: [UUID]) async throws -> [DormIntentEntity] {
        let predicate = #Predicate<Dorm> { dorm in
            identifiers.contains(dorm.id)
        }
        let dorms = try SharedModelUtil.context.fetch(FetchDescriptor(predicate: predicate))
        return dorms.map { DormIntentEntity(id: $0.id, room: $0.room, buildingName: $0.buildingName, campusName: $0.campusName) }
    }

    func defaultResult() async -> DormIntentEntity? {
        try? await suggestedEntities().first
    }
}
