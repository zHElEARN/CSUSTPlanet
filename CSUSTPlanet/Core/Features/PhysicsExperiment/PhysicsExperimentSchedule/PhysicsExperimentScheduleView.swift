//
//  PhysicsExperimentScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import CSUSTKit
import SwiftUI

struct PhysicsExperimentScheduleView: View {
    @State private var data: Cached<[PhysicsExperimentHelper.Course]>? = MMKVHelper.PhysicsExperiment.scheduleCache

    @State private var isLoadingSchedules = false

    @State private var errorToast: ToastState = .errorTitle
    @State private var warningToast: ToastState = .warningTitle

    @State private var isLoginPresented = false

    @State private var isInitial = true

    var body: some View {
        PhysicsExperimentScheduleContent(
            data: data,
            isLoadingSchedules: isLoadingSchedules,
            isLoginPresented: $isLoginPresented,
            errorToast: $errorToast,
            warningToast: $warningToast,
            onRefreshSchedules: loadSchedules
        )
        .onReceive(MMKVHelper.PhysicsExperiment.$scheduleCache.dropFirst().receive(on: RunLoop.main)) { cachedData in
            data = cachedData
        }
        .onChange(of: isLoginPresented) { _, newValue in
            if !newValue { Task { await loadSchedules() } }
        }
        .task {
            guard isInitial else { return }
            isInitial = false
            await loadSchedules()
        }
    }

    // MARK: - Methods

    private func loadSchedules() async {
        guard !isLoadingSchedules else { return }
        isLoadingSchedules = true
        defer { isLoadingSchedules = false }

        do {
            let schedules = try await PhysicsExperimentManager.shared.getCourses()
            let cachedData = Cached(cachedAt: .now, value: schedules)
            MMKVHelper.PhysicsExperiment.scheduleCache = cachedData
            data = cachedData
        } catch {
            if case PhysicsExperimentHelper.PhysicsExperimentError.notLoggedIn = error {
                if let cachedData = MMKVHelper.PhysicsExperiment.scheduleCache {
                    data = cachedData
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        warningToast.show(message: "未登录大物实验，\n已加载上次查询数据（\(cachedData.cachedAt.formatted(.relative(presentation: .named)))）")
                    }
                } else {
                    errorToast.show(message: error.localizedDescription)
                }
            } else {
                if let cachedData = MMKVHelper.PhysicsExperiment.scheduleCache {
                    data = cachedData
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        warningToast.show(message: "错误：\(error.localizedDescription)，\n已加载上次查询数据（\(cachedData.cachedAt.formatted(.relative(presentation: .named)))）")
                    }
                } else {
                    errorToast.show(message: error.localizedDescription)
                }
            }
        }
    }
}
