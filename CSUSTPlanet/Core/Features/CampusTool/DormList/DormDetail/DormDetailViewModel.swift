//
//  DormDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import Foundation
import GRDB
import SwiftUI

@MainActor
@Observable
final class DormDetailViewModel {
    let campusCardHelper = CampusCardHelper()

    var dorm: DormGRDB
    var sortedRecords: [ElectricityRecordGRDB] = []
    var errorToast: ToastState = .errorTitle
    var isQueryingElectricity: Bool = false
    var isDeleteAllRecordsAlertPresented: Bool = false

    var dormObservationCancellable: (any DatabaseCancellable)?

    init(dorm: DormGRDB) {
        self.dorm = dorm
        observeDormDetail()
        refreshSortedRecords()
    }

    func toggleFavorite() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }

        do {
            try pool.write { db in
                guard var targetDorm = try DormGRDB.fetchOne(db, key: dormID) else { return }

                if targetDorm.isFavorite {
                    targetDorm.isFavorite = false
                    try targetDorm.update(db)
                    return
                }

                let favorites = try DormGRDB.filter(DormGRDB.Columns.isFavorite == true).fetchAll(db)
                for var favorite in favorites {
                    favorite.isFavorite = false
                    try favorite.update(db)
                }

                targetDorm.isFavorite = true
                try targetDorm.update(db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func queryElectricity() async {
        guard let dormID = dorm.id else { return }
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
            errorToast.show(message: "无效的校区ID")
            return
        }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }
        guard !isQueryingElectricity else { return }

        isQueryingElectricity = true
        defer { isQueryingElectricity = false }

        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

        do {
            let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)
            try updateDormElectricity(pool: pool, dormID: dormID, electricity: electricity)
            refreshSortedRecords()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func refreshSortedRecords() {
        sortedRecords = fetchSortedRecords()
    }

    private func fetchSortedRecords() -> [ElectricityRecordGRDB] {
        guard let dormID = dorm.id else { return [] }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return []
        }

        do {
            return try pool.read { db in
                try ElectricityRecordGRDB
                    .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                    .order(ElectricityRecordGRDB.Columns.date.desc)
                    .fetchAll(db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
            return []
        }
    }

    func deleteRecord(_ record: ElectricityRecordGRDB) {
        guard let dormID = dorm.id else { return }
        guard let recordID = record.id else { return }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }

        do {
            try pool.write { db in
                _ = try ElectricityRecordGRDB.deleteOne(db, key: recordID)

                let remainingCount =
                    try ElectricityRecordGRDB
                    .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                    .fetchCount(db)

                if remainingCount == 0, var latestDorm = try DormGRDB.fetchOne(db, key: dormID) {
                    latestDorm.lastFetchDate = nil
                    latestDorm.lastFetchElectricity = nil
                    try latestDorm.update(db)
                }
            }
            refreshSortedRecords()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteAllRecords() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }

        do {
            try pool.write { db in
                _ =
                    try ElectricityRecordGRDB
                    .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                    .deleteAll(db)

                if var latestDorm = try DormGRDB.fetchOne(db, key: dormID) {
                    latestDorm.lastFetchDate = nil
                    latestDorm.lastFetchElectricity = nil
                    try latestDorm.update(db)
                }
            }
            sortedRecords = []
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func observeDormDetail() {
        guard let dormID = dorm.id else { return }
        guard dormObservationCancellable == nil else { return }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }

        let observation = ValueObservation.tracking { db in
            try DormGRDB.fetchOne(db, key: dormID)
        }

        dormObservationCancellable = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] (error: any Error) in
                Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { [weak self] (latestDorm: DormGRDB?) in
                guard let latestDorm else { return }
                Task { @MainActor in
                    withAnimation {
                        self?.dorm = latestDorm
                    }
                }
            }
        )
    }

    private func updateDormElectricity(pool: DatabasePool, dormID: Int64, electricity: Double) throws {
        try pool.write { db in
            guard var latestDorm = try DormGRDB.fetchOne(db, key: dormID) else { return }
            let now = Date()

            if let lastFetchElectricity = latestDorm.lastFetchElectricity, abs(lastFetchElectricity - electricity) < 0.001 {
                latestDorm.lastFetchDate = now
            } else {
                var record = ElectricityRecordGRDB(id: nil, electricity: electricity, date: now, dormID: dormID)
                try record.insert(db)
                latestDorm.lastFetchDate = now
                latestDorm.lastFetchElectricity = electricity
            }

            try latestDorm.update(db)
        }
    }
}
