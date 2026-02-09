//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AppIntents
import OSLog
import SwiftData
import SwiftUI
import TipKit
import Toasts

@main
struct CSUSTPlanetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    private static var isFirstAppear = true
    private static var lastBackgroundDate: Date?

    init() {
        #if DEBUG
            try? Tips.resetDatastore()
        #endif
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
        ])

        ActivityHelper.shared.setup()
        NotificationManager.shared.setup()
        TrackHelper.shared.setup()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .installToast(position: .top)
                .environmentObject(GlobalManager.shared)
                .environmentObject(AuthManager.shared)
                .environmentObject(NotificationManager.shared)
        }
        .modelContainer(SharedModelUtil.container)
        .onChange(of: scenePhase) { _, newPhase in handleScenePhaseChange(to: newPhase) }
    }

    private func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .active:
            Logger.app.debug("App进入活跃状态: scenePhase .active")
            ActivityHelper.shared.autoUpdateActivity()
            if !Self.isFirstAppear {
                checkAndRelogin()
                TrackHelper.shared.event(category: "Lifecycle", action: "Active")
            }
            if Self.isFirstAppear {
                Self.isFirstAppear = false
                TrackHelper.shared.event(category: "Lifecycle", action: "Launch")
            }
        case .inactive:
            Logger.app.debug("App进入非活跃状态: scenePhase .inactive")
            ActivityHelper.shared.autoUpdateActivity()
            TrackHelper.shared.event(category: "Lifecycle", action: "Inactive")
            Self.lastBackgroundDate = .now
        case .background:
            Logger.app.debug("App进入后台状态: scenePhase .background")
            TrackHelper.shared.event(category: "Lifecycle", action: "Background")
        default:
            break
        }
    }

    private func checkAndRelogin() {
        let threshold: TimeInterval = 20 * 60
        guard let backgroundDate = Self.lastBackgroundDate else { return }
        let timeInterval = Date().timeIntervalSince(backgroundDate)
        if timeInterval > threshold {
            Logger.app.debug("App后台停留时间 (\(timeInterval)s) 超过阈值，执行 SSO Relogin")
            AuthManager.shared.ssoRelogin()
        } else {
            Logger.app.debug("App后台停留时间 (\(timeInterval)s) 不足 20 分钟，跳过 Relogin")
        }
    }
}
