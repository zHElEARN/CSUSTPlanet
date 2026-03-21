//
//  DormListViewModel.swift
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
final class DormListViewModel {
    let campusCardHelper = CampusCardHelper()

    var isAddDormSheetPresented: Bool = false
    var dorms: [DormGRDB] = []
    var errorToast: ToastState = .errorTitle
    var queryingDormIDs: Set<Int64> = []
    var targetDeleteDorm: DormGRDB?

    var dormObservationCancellable: (any DatabaseCancellable)?

    init() {
        guard dormObservationCancellable == nil else { return }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }
        let observation = ValueObservation.tracking { db in
            try DormGRDB.order(DormGRDB.Columns.id.desc).fetchAll(db)
        }

        dormObservationCancellable = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] error in
                Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { [weak self] dorms in
                Task { @MainActor in withAnimation { self?.dorms = dorms } }
            }
        )
    }

    func addDorm(building: CampusCardHelper.Building, room: String) {
        guard !room.isEmpty else {
            errorToast.show(message: "宿舍号不能为空")
            return
        }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }

        do {
            try pool.write { db in
                let duplicated =
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room)
                    .filter(DormGRDB.Columns.buildingID == building.id)
                    .fetchOne(db) != nil
                if duplicated {
                    errorToast.show(message: "该宿舍信息已存在")
                    return
                }

                var dorm = DormGRDB(
                    id: nil,
                    room: room,
                    buildingID: building.id,
                    buildingName: building.name,
                    campusID: building.campus.id,
                    campusName: building.campus.rawValue,
                    isFavorite: false,
                    lastFetchDate: nil,
                    lastFetchElectricity: nil,
                    scheduleHour: nil,
                    scheduleMinute: nil
                )
                try dorm.insert(db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteDorm(_ dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }

        do {
            try pool.write { db in
                _ = try DormGRDB.deleteOne(db, key: dormID)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func toggleFavorite(_ dorm: DormGRDB) {
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

    func isQuerying(_ dorm: DormGRDB) -> Bool {
        guard let dormID = dorm.id else { return false }
        return queryingDormIDs.contains(dormID)
    }

    func queryElectricity(for dorm: DormGRDB) async {
        guard let dormID = dorm.id else { return }
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
            errorToast.show(message: "无效的校区ID")
            return
        }
        guard let pool = DatabaseManager.shared.pool else {
            errorToast.show(message: "数据库未初始化")
            return
        }
        guard !queryingDormIDs.contains(dormID) else { return }

        queryingDormIDs.insert(dormID)
        defer { queryingDormIDs.remove(dormID) }

        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

        do {
            let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)
            try updateDormElectricity(pool: pool, dormID: dormID, electricity: electricity)
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
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
