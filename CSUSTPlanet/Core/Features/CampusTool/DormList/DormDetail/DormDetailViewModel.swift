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
    var chartRecords: [ElectricityRecordGRDB] = []
    var chartYDomain: ClosedRange<Double> = 0...2
    var exhaustionInfo: String?
    var errorToast: ToastState = .errorTitle
    var isQueryingElectricity: Bool = false
    var isDeleteAllRecordsAlertPresented: Bool = false

    var dormObservationCancellable: (any DatabaseCancellable)?
    var recordsObservationCancellable: (any DatabaseCancellable)?

    init(dorm: DormGRDB) {
        self.dorm = dorm
        observeDormDetail()
        observeRecords()
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
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteRecord(_ record: ElectricityRecordGRDB) {
        guard let dormID = dorm.id else { return }
        guard let recordID = record.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteElectricityRecord(dormID: dormID, recordID: recordID, in: db) }
            // 移除手动 refreshSortedRecords()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func deleteAllRecords() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteAllElectricityRecords(dormID: dormID, in: db) }
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

    private func observeRecords() {
        guard let dormID = dorm.id else { return }
        guard recordsObservationCancellable == nil else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db in
            try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                .order(ElectricityRecordGRDB.Columns.date.desc)
                .fetchAll(db)
        }

        recordsObservationCancellable = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] error in
                Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { [weak self] records in
                Task { @MainActor in
                    withAnimation(.snappy) {
                        self?.sortedRecords = records

                        let recordsAscending = Array(records.reversed())
                        let chartRecords = ElectricityUtil.downsample(from: recordsAscending, to: 120)
                        let minValue = chartRecords.map(\.electricity).min() ?? 0
                        let maxValue = chartRecords.map(\.electricity).max() ?? 0
                        let yMin = max(0, minValue - 2)
                        let yMax = max(yMin + 1, maxValue + 2)
                        self?.chartRecords = chartRecords
                        self?.chartYDomain = yMin...yMax

                        self?.exhaustionInfo = ElectricityUtil.getExhaustionInfo(from: Array(records.reversed()))
                    }
                }
            }
        )
    }
}
