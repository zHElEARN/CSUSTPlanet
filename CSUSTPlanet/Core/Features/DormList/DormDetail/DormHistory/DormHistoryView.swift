//
//  DormHistoryView.swift
//  CSUSTPlanet
//
//  Created by OpenCode on 2026/3/22.
//

import GRDB
import SwiftUI

struct DormHistoryView: View {
    let params: DormParams

    @State private var records: [ElectricityRecordGRDB] = []
    @State private var errorToast: ToastState = .errorTitle

    @State private var recordsObserver: (any DatabaseCancellable)?
    @State private var hasStartedObservation = false

    var body: some View {
        DormHistoryContent(
            records: records,
            errorToast: $errorToast,
            onDelete: deleteRecord
        )
        .task { startObservationIfNeeded() }
    }

    // MARK: - Observation

    private func startObservationIfNeeded() {
        guard !hasStartedObservation else { return }
        hasStartedObservation = true

        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db in
            let recentStartDate = ElectricityUtil.recentRecordsStartDate()
            return
                try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == params.dormID)
                .filter(ElectricityRecordGRDB.Columns.date >= recentStartDate)
                .order(ElectricityRecordGRDB.Columns.date.desc)
                .fetchAll(db)
        }

        recordsObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { error in
                Task { @MainActor in
                    self.errorToast.show(message: error.localizedDescription)
                }
            },
            onChange: { newRecords in
                Task { @MainActor in
                    withAnimation {
                        self.records = newRecords
                    }
                }
            }
        )
    }

    // MARK: - Actions

    private func deleteRecord(_ record: ElectricityRecordGRDB) {
        guard let recordID = record.id else { return }
        guard let pool = DatabaseManager.shared.pool else { return }

        do {
            try pool.write { db in
                try DormGRDB.deleteElectricityRecord(dormID: params.dormID, recordID: recordID, in: db)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
