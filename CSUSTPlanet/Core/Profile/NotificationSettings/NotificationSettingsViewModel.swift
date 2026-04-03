//
//  NotificationSettingsViewModel.swift
//  CSUSTPlanet
//
//  Created by OpenAI Codex on 2026/4/3.
//

import Foundation
import GRDB
import SwiftUI

@MainActor
@Observable
final class NotificationSettingsViewModel {
    var scheduledDorms: [DormGRDB] = []
    var targetCancelDorm: DormGRDB?
    var errorToast: ToastState = .errorTitle
    var isSchedulingDorm: Bool = false

    private var listObserver: (any DatabaseCancellable)?

    var isInitial: Bool = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        observeScheduledDorms()
    }

    func presentCancelScheduleAlert(for dorm: DormGRDB) {
        targetCancelDorm = dorm
    }

    func dismissCancelScheduleAlert() {
        targetCancelDorm = nil
    }

    func confirmCancelSchedule() async {
        guard let targetCancelDorm else { return }
        dismissCancelScheduleAlert()
        await cancelSchedule(for: targetCancelDorm)
    }

    private func cancelSchedule(for dorm: DormGRDB) async {
        guard let dormID = dorm.id else { return }
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

            let permissionStatus = NotificationManager.shared.permissionStatus ?? .denied
            try await pool.write { db in
                try DormGRDB.clearSchedule(dormID: dormID, in: db)
            }

            try await PlanetTaskService.shared.sync(
                permissionStatus: permissionStatus,
                deviceToken: deviceToken,
                authToken: authToken
            )
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func observeScheduledDorms() {
        guard let pool = DatabaseManager.shared.pool else { return }

        let observation = ValueObservation.tracking { db in
            try DormGRDB
                .filter(DormGRDB.Columns.scheduleHour != nil && DormGRDB.Columns.scheduleMinute != nil)
                .order(DormGRDB.Columns.id.desc)
                .fetchAll(db)
        }

        listObserver = observation.start(
            in: pool,
            scheduling: .immediate,
            onError: { [weak self] error in
                Task { @MainActor in
                    self?.errorToast.show(message: error.localizedDescription)
                }
            },
            onChange: { [weak self] dorms in
                Task { @MainActor in
                    withAnimation {
                        self?.scheduledDorms = dorms
                    }
                }
            }
        )
    }
}
