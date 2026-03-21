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
    var isAddDormSheetPresented: Bool = false
    var dorms: [DormGRDB] = []
    var errorToast: ToastState = .errorTitle

    var dormObservationCancellable: (any DatabaseCancellable)?

    func startObserveDorms() {
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
                Task { @MainActor in self?.dorms = dorms }
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
}
