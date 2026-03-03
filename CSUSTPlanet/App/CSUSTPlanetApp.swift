//
//  CSUSTPlanetApp.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AppIntents
import OSLog
import Sentry
import SwiftData
import SwiftUI
import TipKit

#if os(iOS)
import Toasts
#endif

@main
struct CSUSTPlanetApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @Environment(\.scenePhase) private var scenePhase

    private static var isFirstAppear = true
    private static var lastBackgroundDate: Date?

    init() {
        SentrySDK.start { options in
            options.dsn = Constants.sentryDSN
            // #if DEBUG
            //     options.debug = true
            // #endif
            options.environment = EnvironmentUtil.environment.rawValue
        }

        #if DEBUG
        try? Tips.resetDatastore()
        #endif
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
        ])

        #if os(iOS)
        BackgroundTaskHelper.shared.registerAllTasks()
        ActivityHelper.shared.setup()
        NotificationManager.shared.setup()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(iOS)
            .installToast(position: .top)
                #endif
                .environmentObject(GlobalManager.shared)
                .environmentObject(AuthManager.shared)
                #if os(iOS)
            .environmentObject(NotificationManager.shared)
            #endif
        }
        .modelContainer(SharedModelUtil.container)
        .onChange(of: scenePhase) { _, newPhase in handleScenePhaseChange(to: newPhase) }
    }

    private func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .active:
            Logger.app.debug("App进入活跃状态: scenePhase .active")
            #if os(iOS)
            ActivityHelper.shared.autoUpdateActivity()
            #endif
            if !Self.isFirstAppear {
                checkAndRelogin()
                #if os(iOS)
                BackgroundTaskHelper.shared.cancelAllTasks()
                #endif
                TrackHelper.shared.event(category: "Lifecycle", action: "Active")
            }
            if Self.isFirstAppear {
                Self.isFirstAppear = false
                TrackHelper.shared.event(category: "Lifecycle", action: "Launch")
                runDataCleanupTaskIfNeed()
            }
        case .inactive:
            Logger.app.debug("App进入非活跃状态: scenePhase .inactive")
            #if os(iOS)
            ActivityHelper.shared.autoUpdateActivity()
            BackgroundTaskHelper.shared.scheduleAllTasks()
            #endif
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

    private func runDataCleanupTaskIfNeed() {
        guard !MMKVHelper.shared.hasCleanedUpDuplicateElectricityRecords else { return }
        Task {
            let cleaner = ElectricityRecordCleaner(modelContainer: SharedModelUtil.container)
            await cleaner.cleanUpDuplicateRecords()
            MMKVHelper.shared.hasCleanedUpDuplicateElectricityRecords = true
        }
    }
}
