//
//  DormListView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import Combine
import GRDB
import SwiftUI

struct DormListView: View {
    @State private var dorms: [DormGRDB] = []
    @State private var exhaustionInfoMap: [Int64: String] = [:]
    @State private var isLoading = true
    @State private var errorToast: ToastState = .errorTitle
    @State private var queryingDormIDs: Set<Int64> = []

    @State private var listObserver: (any DatabaseCancellable)?
    @State private var ipcCancellable: AnyCancellable?
    @State private var isFirstObservation = true
    @State private var hasStartedObservation = false

    var body: some View {
        DormListContent(
            dorms: dorms,
            exhaustionInfoMap: exhaustionInfoMap,
            isLoading: isLoading,
            queryingDormIDs: queryingDormIDs,
            errorToast: $errorToast,
            onAddDorm: addDorm,
            onDeleteDorm: deleteDorm,
            onToggleFavorite: toggleFavorite,
            onQuery: queryElectricity
        )
        .task { startObservationIfNeeded() }
    }

    // MARK: - Observation

    private func startObservationIfNeeded() {
        guard !hasStartedObservation else { return }
        hasStartedObservation = true

        setupIPCObservationIfNeeded()
        restartListObservation()
    }

    private func setupIPCObservationIfNeeded() {
        guard ipcCancellable == nil else { return }

        ipcCancellable = GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { _ in
                Task { @MainActor in
                    self.restartListObservation()
                }
            }
    }

    private func restartListObservation() {
        listObserver?.cancel()
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db -> ([DormGRDB], [ElectricityRecordGRDB]) in
            let dorms = try DormGRDB.order(DormGRDB.Columns.id.desc).fetchAll(db)
            let recentStartDate = ElectricityUtil.recentRecordsStartDate()
            let records =
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.date >= recentStartDate)
                .order(ElectricityRecordGRDB.Columns.date.asc)
                .fetchAll(db)
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

        listObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { error in
                Task { @MainActor in
                    self.errorToast.show(message: error.localizedDescription)
                }
            },
            onChange: { result in
                Task { @MainActor in
                    if self.isFirstObservation {
                        self.isFirstObservation = false
                        self.dorms = result.0
                        self.exhaustionInfoMap = result.1
                        self.isLoading = false
                    } else {
                        withAnimation {
                            self.dorms = result.0
                            self.exhaustionInfoMap = result.1
                        }
                    }
                }
            }
        )
    }

    // MARK: - Actions

    private func addDorm(room: CampusCardHelper.Room) {
        guard let pool = DatabaseManager.shared.pool else { return }

        let building = room.building
        let campus = building.campus

        do {
            try pool.write { db in
                let duplicated =
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room.name)
                    .filter(DormGRDB.Columns.buildingName == building.name)
                    .filter(DormGRDB.Columns.campusName == campus.rawValue)
                    .fetchOne(db) != nil
                if duplicated {
                    errorToast.show(message: "该宿舍信息已存在")
                    return
                }

                var dorm = DormGRDB(
                    id: nil,
                    room: room.name,
                    buildingName: building.name,
                    campusName: building.campus.rawValue,
                    isFavorite: false,
                    lastFetchDate: nil,
                    lastFetchElectricity: nil
                )
                try dorm.insert(db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func deleteDorm(_ dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in _ = try DormGRDB.deleteOne(db, key: dormID) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func toggleFavorite(_ dorm: DormGRDB) {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.toggleFavorite(dormID: dormID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func queryElectricity(for dorm: DormGRDB) async {
        guard let dormID = dorm.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !queryingDormIDs.contains(dormID) else { return }
        queryingDormIDs.insert(dormID)
        defer { queryingDormIDs.remove(dormID) }

        do {
            let electricity = try await ElectricityUtil.getElectricity(
                AuthManager.shared.campusCardHelper,
                campusName: dorm.campusName,
                buildingName: dorm.buildingName,
                roomName: dorm.room,
                retryProvider: AuthManager.shared
            )
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: dormID, electricity: electricity, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
