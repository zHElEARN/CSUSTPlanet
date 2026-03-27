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
    var exhaustionInfoMap: [Int64: String] = [:]

    private var listObserver: AutoRefreshingObserver?

    var isInitial: Bool = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        observeList()
    }

    func observeList() {
        guard let pool = DatabaseManager.shared.pool else { return }

        listObserver = AutoRefreshingObserver { [weak self] in
            let observation = ValueObservation.tracking { db -> ([DormGRDB], [ElectricityRecordGRDB]) in
                let dorms = try DormGRDB.order(DormGRDB.Columns.id.desc).fetchAll(db)
                let records = try ElectricityRecordGRDB.order(ElectricityRecordGRDB.Columns.date.asc).fetchAll(db)
                return (dorms, records)
            }
            .map { (dorms, records) -> ([DormGRDB], [Int64: String]) in
                let recordsByDormID = Dictionary(grouping: records, by: { $0.dormID })
                var infoMap: [Int64: String] = [:]
                infoMap.reserveCapacity(dorms.count)

                for dorm in dorms {
                    guard let dormID = dorm.id else { continue }
                    let dormRecords = recordsByDormID[dormID] ?? []
                    infoMap[dormID] = ElectricityUtil.getExhaustionInfo(from: dormRecords)
                }
                return (dorms, infoMap)
            }

            return observation.start(
                in: pool,
                scheduling: .immediate,
                onError: { [weak self] error in
                    Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
                },
                onChange: { [weak self] result in
                    Task { @MainActor in
                        withAnimation {
                            self?.dorms = result.0
                            self?.exhaustionInfoMap = result.1
                        }
                    }
                }
            )
        }
    }

    func addDorm(building: CampusCardHelper.Building, room: String) {
        guard let pool = DatabaseManager.shared.pool else { return }

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
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in _ = try DormGRDB.deleteOne(db, key: dormID) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func toggleFavorite(_ dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.toggleFavorite(dormID: dormID, in: db) }
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
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !queryingDormIDs.contains(dormID) else { return }
        queryingDormIDs.insert(dormID)
        defer { queryingDormIDs.remove(dormID) }

        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

        do {
            let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func configureSchedule(for dorm: DormGRDB, hour: Int, minute: Int) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.updateSchedule(dormID: dormID, hour: hour, minute: minute, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func cancelSchedule(for dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.clearSchedule(dormID: dormID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
