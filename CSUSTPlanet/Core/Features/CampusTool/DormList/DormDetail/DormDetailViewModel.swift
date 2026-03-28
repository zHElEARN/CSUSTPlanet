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
    var isScheduleConfigSheetPresented: Bool = false
    var isCancelScheduleAlertPresented: Bool = false
    var isNotificationDeniedAlertPresented: Bool = false
    var isSchedulingDorm: Bool = false

    private var dormObserver: AutoRefreshingObserver?
    private var recordsObserver: AutoRefreshingObserver?

    var isInitial: Bool = true

    init(dorm: DormGRDB) {
        self.dorm = dorm
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
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

    func configureSchedule(hour: Int, minute: Int) async {
        guard let dormID = dorm.id else { return }

        await performScheduleUpdate { db in
            try DormGRDB.updateSchedule(dormID: dormID, hour: hour, minute: minute, in: db)
        }
    }

    func cancelSchedule() async {
        guard let dormID = dorm.id else { return }

        await performScheduleUpdate { db in
            try DormGRDB.clearSchedule(dormID: dormID, in: db)
        }
    }

    private func observeDormDetail() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        dormObserver = AutoRefreshingObserver { [weak self] in
            let observation = ValueObservation.tracking { db in
                try DormGRDB.fetchOne(db, key: dormID)
            }

            return observation.start(
                in: pool,
                scheduling: .immediate,
                onError: { [weak self] error in
                    Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
                },
                onChange: { [weak self] latestDorm in
                    guard let latestDorm else { return }
                    Task { @MainActor in withAnimation { self?.dorm = latestDorm } }
                }
            )
        }
    }

    private func observeRecords() {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        struct ProcessedDetailData {
            let sortedRecords: [ElectricityRecordGRDB]
            let chartRecords: [ElectricityRecordGRDB]
            let chartYDomain: ClosedRange<Double>
            let exhaustionInfo: String?
        }

        recordsObserver = AutoRefreshingObserver { [weak self] in
            let observation = ValueObservation.tracking { db in
                let recentStartDate = ElectricityUtil.recentRecordsStartDate()
                return
                    try ElectricityRecordGRDB
                    .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                    .filter(ElectricityRecordGRDB.Columns.date >= recentStartDate)
                    .order(ElectricityRecordGRDB.Columns.date.desc)
                    .fetchAll(db)
            }
            .map { records -> ProcessedDetailData in
                let sortedRecords = records
                let recordsAscending = Array(records.reversed())
                let chartRecords = ElectricityUtil.downsample(from: recordsAscending, to: 150)
                let exhaustionInfo = ElectricityUtil.getExhaustionInfo(from: recordsAscending)

                return ProcessedDetailData(
                    sortedRecords: sortedRecords,
                    chartRecords: chartRecords,
                    chartYDomain: ElectricityUtil.chartYDomain(for: chartRecords),
                    exhaustionInfo: exhaustionInfo
                )
            }

            return observation.start(
                in: pool,
                scheduling: .immediate,
                onError: { [weak self] error in
                    Task { @MainActor in self?.errorToast.show(message: error.localizedDescription) }
                },
                onChange: { [weak self] data in
                    Task { @MainActor in
                        withAnimation {
                            self?.sortedRecords = data.sortedRecords
                            self?.chartRecords = data.chartRecords
                            self?.chartYDomain = data.chartYDomain
                            self?.exhaustionInfo = data.exhaustionInfo
                        }
                    }
                }
            )
        }
    }

    private func performScheduleUpdate(dbAction: @escaping (Database) throws -> Void) async {
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !isSchedulingDorm else { return }
        isSchedulingDorm = true
        defer { isSchedulingDorm = false }

        do {
            guard let authToken = PlanetAuthService.shared.authToken else {
                errorToast.show(message: "需要登录账号以设置宿舍电量定时通知")
                return
            }
            guard let deviceToken = NotificationManager.shared.token else {
                errorToast.show(message: "无法获取设备通知令牌")
                return
            }
            guard let permissionStatus = NotificationManager.shared.permissionStatus else {
                errorToast.show(message: "无法获取通知权限状态")
                return
            }

            switch permissionStatus {
            case .authorized:
                break
            case .denied:
                isNotificationDeniedAlertPresented = true
                return
            case .requestable:
                guard try await NotificationManager.shared.requestPermission() else {
                    isNotificationDeniedAlertPresented = true
                    return
                }
            }

            try await pool.write { db in
                try dbAction(db)
            }

            try await PlanetTaskService.shared.sync(permissionStatus: permissionStatus, deviceToken: deviceToken, authToken: authToken)

        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
