//
//  DormMigrationPlan.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/1/11.
//

import Foundation
import SwiftData

enum DormMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        return [DormSchemaV1.self, DormSchemaV2.self, DormSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        return [migrateV1ToV2, migrateV2ToV3]
    }

    static let migrateV1ToV2: MigrationStage = .custom(
        fromVersion: DormSchemaV1.self,
        toVersion: DormSchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let dormDescriptor = FetchDescriptor<DormSchemaV2.Dorm>()
            let dorms = try context.fetch(dormDescriptor)
            for dorm in dorms {
                let targetDormID = dorm.id
                var recordDescriptor = FetchDescriptor<DormSchemaV2.ElectricityRecord>(
                    predicate: #Predicate { $0.dorm?.id == targetDormID },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                recordDescriptor.fetchLimit = 1
                if let latestRecord = try context.fetch(recordDescriptor).first {
                    dorm.lastFetchDate = latestRecord.date
                }
            }
            try context.save()
        }
    )

    static let migrateV2ToV3: MigrationStage = .custom(
        fromVersion: DormSchemaV2.self,
        toVersion: DormSchemaV3.self,
        willMigrate: nil,
        didMigrate: { context in
            let dormDescriptor = FetchDescriptor<DormSchemaV3.Dorm>()
            let dorms = try context.fetch(dormDescriptor)
            for dorm in dorms {
                let targetDormID = dorm.id
                var recordDescriptor = FetchDescriptor<DormSchemaV3.ElectricityRecord>(
                    predicate: #Predicate { $0.dorm?.id == targetDormID },
                    sortBy: [SortDescriptor(\.date, order: .reverse)]
                )
                recordDescriptor.fetchLimit = 1
                if let latestRecord = try context.fetch(recordDescriptor).first {
                    dorm.lastFetchElectricity = latestRecord.electricity
                }
            }
            try context.save()
        }
    )
}
