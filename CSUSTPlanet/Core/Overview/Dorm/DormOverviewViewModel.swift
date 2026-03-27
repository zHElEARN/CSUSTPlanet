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
    var primaryDorm: DormGRDB?
    var electricityExhaustionInfo: String?

    private var dormObserver: AutoRefreshingObserver?

    func onAppear() {
        observePrimaryDorm()
    }

    private func observePrimaryDorm() {
        guard let pool = DatabaseManager.shared.pool else {
            primaryDorm = nil
            electricityExhaustionInfo = nil
            return
        }

        struct ProcessedDormOverviewData {
            let dorm: DormGRDB?
            let exhaustionInfo: String?
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
            .map { dorm, records in
                ProcessedDormOverviewData(
                    dorm: dorm,
                    exhaustionInfo: ElectricityUtil.getExhaustionInfo(from: records)
                )
            }

            return observation.start(
                in: pool,
                scheduling: .immediate,
                onError: { _ in
                    Task { @MainActor in
                        self?.primaryDorm = nil
                        self?.electricityExhaustionInfo = nil
                    }
                },
                onChange: { [weak self] data in
                    Task { @MainActor in
                        withAnimation {
                            self?.primaryDorm = data.dorm
                            self?.electricityExhaustionInfo = data.exhaustionInfo
                        }
                    }
                }
            )
        }
    }
}
