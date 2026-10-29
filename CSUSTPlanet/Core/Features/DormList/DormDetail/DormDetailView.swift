//
//  DormDetailView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import Combine
import GRDB
import SwiftUI

struct DormDetailView: View {
    let params: DormParams

    @State private var dorm: DormGRDB?
    @State private var sortedRecords: [ElectricityRecordGRDB] = []
    @State private var chartRecords: [ElectricityRecordGRDB] = []
    @State private var chartYDomain: ClosedRange<Double> = 0...2
    @State private var exhaustionInfo: String?
    @State private var errorToast: ToastState = .errorTitle
    @State private var isQueryingElectricity = false

    @State private var dormObserver: (any DatabaseCancellable)?
    @State private var recordsObserver: (any DatabaseCancellable)?
    @State private var ipcCancellable: AnyCancellable?
    @State private var hasStartedObservation = false

    var body: some View {
        Group {
            if let dorm {
                DormDetailContent(
                    params: params,
                    dorm: dorm,
                    sortedRecords: sortedRecords,
                    chartRecords: chartRecords,
                    chartYDomain: chartYDomain,
                    exhaustionInfo: exhaustionInfo,
                    isQueryingElectricity: isQueryingElectricity,
                    errorToast: $errorToast,
                    onQuery: queryElectricity,
                    onToggleFavorite: toggleFavorite,
                    onDeleteRecord: deleteRecord,
                    onDeleteAllRecords: deleteAllRecords
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("宿舍详情")
            }
        }
        .task { startObservationIfNeeded() }
    }

    // MARK: - Observation

    private func startObservationIfNeeded() {
        guard !hasStartedObservation else { return }
        hasStartedObservation = true

        setupIPCObservationIfNeeded()
        restartGRDBObservations()
    }

    private func setupIPCObservationIfNeeded() {
        guard ipcCancellable == nil else { return }

        ipcCancellable = GRDBIPCNotifier.shared.dbChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { _ in
                Task { @MainActor in
                    self.restartGRDBObservations()
                }
            }
    }

    private func restartGRDBObservations() {
        observeDormDetail()
        observeRecords()
    }

    private func observeDormDetail() {
        dormObserver?.cancel()
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db in
            try DormGRDB.fetchOne(db, key: params.dormID)
        }

        dormObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { error in
                Task { @MainActor in self.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { latestDorm in
                guard let latestDorm else { return }
                Task { @MainActor in withAnimation { self.dorm = latestDorm } }
            }
        )
    }

    private func observeRecords() {
        recordsObserver?.cancel()
        guard let pool = DatabaseManager.shared.pool else { return }

        struct ProcessedDetailData {
            let sortedRecords: [ElectricityRecordGRDB]
            let chartRecords: [ElectricityRecordGRDB]
            let chartYDomain: ClosedRange<Double>
            let exhaustionInfo: String?
        }

        let observation = ValueObservation.tracking { db in
            let recentStartDate = ElectricityUtil.recentRecordsStartDate()
            return
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == params.dormID)
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

        recordsObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { error in
                Task { @MainActor in self.errorToast.show(message: error.localizedDescription) }
            },
            onChange: { data in
                Task { @MainActor in
                    withAnimation {
                        self.sortedRecords = data.sortedRecords
                        self.chartRecords = data.chartRecords
                        self.chartYDomain = data.chartYDomain
                        self.exhaustionInfo = data.exhaustionInfo
                    }
                }
            }
        )
    }

    // MARK: - Actions

    private func toggleFavorite() {
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.toggleFavorite(dormID: params.dormID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func queryElectricity() async {
        guard let dorm else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        guard !isQueryingElectricity else { return }
        isQueryingElectricity = true
        defer { isQueryingElectricity = false }

        do {
            let electricity = try await ElectricityUtil.getElectricity(
                AuthManager.shared.campusCardHelper,
                campusName: dorm.campusName,
                buildingName: dorm.buildingName,
                roomName: dorm.room,
                retryProvider: AuthManager.shared
            )
            try await pool.write { db in try DormGRDB.updateElectricity(dormID: params.dormID, electricity: electricity, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func deleteRecord(_ record: ElectricityRecordGRDB) {
        guard let recordID = record.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteElectricityRecord(dormID: params.dormID, recordID: recordID, in: db) }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func deleteAllRecords() {
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in try DormGRDB.deleteAllElectricityRecords(dormID: params.dormID, in: db) }
            WidgetTimelineRefreshHelper.reloadDormElectricity()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
