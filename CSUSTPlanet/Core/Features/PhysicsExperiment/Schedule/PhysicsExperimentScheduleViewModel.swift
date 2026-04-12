//
//  PhysicsExperimentScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
class PhysicsExperimentScheduleViewModel {
    var data: Cached<[PhysicsExperimentHelper.Course]>? = nil

    var isLoadingSchedules = false

    var errorToast: ToastState = .errorTitle
    var warningToast: ToastState = .warningTitle

    @ObservationIgnored var isInitial = true

    init() {
        guard let data = MMKVHelper.PhysicsExperiment.scheduleCache else { return }
        self.data = data
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadSchedules()
    }

    func loadSchedules() async {
        guard !isLoadingSchedules else { return }
        isLoadingSchedules = true
        defer { isLoadingSchedules = false }

        do {
            let schedules = try await PhysicsExperimentManager.shared.getCourses()
            let data = Cached(cachedAt: .now, value: schedules)
            self.data = data
            MMKVHelper.PhysicsExperiment.scheduleCache = data
        } catch {
            if case PhysicsExperimentHelper.PhysicsExperimentError.notLoggedIn = error {
                if let cachedData = MMKVHelper.PhysicsExperiment.scheduleCache {
                    self.data = cachedData
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningToast.show(message: "未登录大物实验，\n已加载上次查询数据（\(cachedData.cachedAt.formatted(.relative(presentation: .named)))）")
                    }
                } else {
                    self.errorToast.show(message: error.localizedDescription)
                }
            } else {
                if let cachedData = MMKVHelper.PhysicsExperiment.scheduleCache {
                    self.data = cachedData
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningToast.show(message: "错误：\(error.localizedDescription)，\n已加载上次查询数据（\(cachedData.cachedAt.formatted(.relative(presentation: .named)))）")
                    }
                } else {
                    self.errorToast.show(message: error.localizedDescription)
                }
            }
        }
    }
}
