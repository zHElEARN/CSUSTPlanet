//
//  DormOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import GRDB
import SwiftUI

@MainActor
@Observable
final class DormOverviewViewModel {
    private struct ProcessedDormOverviewData {
        let dorm: DormGRDB?
        let exhaustionInfo: String?
        let chartRecords: [ElectricityRecordGRDB]
        let chartYDomain: ClosedRange<Double>
    }

    var primaryDorm: DormGRDB?
    var electricityExhaustionInfo: String?
    var chartRecords: [ElectricityRecordGRDB] = []
    var chartYDomain: ClosedRange<Double> = 0...2

    private var dormObserver: AutoRefreshingObserver?

    func onAppear() {
        observePrimaryDorm()
    }

    private func observePrimaryDorm() {
        guard let pool = DatabaseManager.shared.pool else {
            primaryDorm = nil
            electricityExhaustionInfo = nil
            chartRecords = []
            chartYDomain = 0...2
            return
        }

        dormObserver = AutoRefreshingObserver { [weak self] in
            let observation = ValueObservation.tracking { db -> (DormGRDB?, [ElectricityRecordGRDB]) in
                let favoriteDorm =
                    try DormGRDB
                    .filter(DormGRDB.Columns.isFavorite == true)
                    .fetchOne(db)

                let dorm = try favoriteDorm ?? DormGRDB.order(DormGRDB.Columns.id.asc).fetchOne(db)
                guard let dormID = dorm?.id else { return (dorm, []) }

                let records =
                    try ElectricityRecordGRDB
                    .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                    .order(ElectricityRecordGRDB.Columns.date.asc)
                    .fetchAll(db)

                return (dorm, records)
            }
            .map { (dorm, records) -> ProcessedDormOverviewData in
                let sampledRecords = ElectricityUtil.downsample(from: records, to: 80)

                return ProcessedDormOverviewData(
                    dorm: dorm,
                    exhaustionInfo: ElectricityUtil.getExhaustionInfo(from: records),
                    chartRecords: sampledRecords,
                    chartYDomain: ElectricityUtil.chartYDomain(for: sampledRecords)
                )
            }

            return observation.start(
                in: pool,
                scheduling: .immediate,
                onError: { _ in
                    Task { @MainActor in
                        self?.primaryDorm = nil
                        self?.electricityExhaustionInfo = nil
                        self?.chartRecords = []
                        self?.chartYDomain = 0...2
                    }
                },
                onChange: { [weak self] data in
                    Task { @MainActor in
                        withAnimation {
                            self?.primaryDorm = data.dorm
                            self?.electricityExhaustionInfo = data.exhaustionInfo
                            self?.chartRecords = data.chartRecords
                            self?.chartYDomain = data.chartYDomain
                        }
                    }
                }
            )
        }
    }
}
