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
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.toggleFavorite(dormID: dormID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func queryElectricity() async {
        guard let dormID = dorm.id else { return }
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !isQueryingElectricity else { return }
        isQueryingElectricity = true
        defer { isQueryingElectricity = false }

        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

        do {
            let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
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
        guard let pool = DatabaseManager.shared.pool else { return [] }

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
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteElectricityRecord(dormID: dormID, recordID: recordID, in: db) }
            refreshSortedRecords()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteAllRecords() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteAllElectricityRecords(dormID: dormID, in: db) }
            sortedRecords = []
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func observeDormDetail() {
        guard let dormID = dorm.id else { return }
        guard dormObservationCancellable == nil else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

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
                Task { @MainActor in withAnimation { self?.dorm = latestDorm } }
            }
        )
    }

}
