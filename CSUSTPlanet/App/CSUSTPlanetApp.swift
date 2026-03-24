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

@main
struct CSUSTPlanetApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @Environment(\.scenePhase) private var scenePhase

    private static var isFirstAppear = true
    private static var lastBackgroundDate: Date?

    init() {
        _ = DatabaseManager.shared
        GlobalManager.shared.hasDatabaseFatalError = DatabaseManager.shared.hasFatalError
        GlobalManager.shared.databaseFatalErrorMessage = DatabaseManager.shared.fatalErrorMessage

        TrackHelper.shared.event(category: "Lifecycle", action: "Launch")

        SentrySDK.start { options in
            options.dsn = Constants.sentryDSN
            // #if DEBUG
            // options.debug = true
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
        BackgroundTaskHelper.shared.register()
        _ = ActivityManager.shared
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
            .frame(
                minWidth: 400, idealWidth: 800, maxWidth: 1200,
                minHeight: 600, idealHeight: 800, maxHeight: 1000
            )
                #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        #endif
        // .modelContainer(SharedModelUtil.container)
        .onChange(of: scenePhase) { _, newPhase in handleScenePhaseChange(to: newPhase) }
    }

    private func handleScenePhaseChange(to phase: ScenePhase) {
        switch phase {
        case .active:
            // 首次启动时不处理
            if Self.isFirstAppear {
                Self.isFirstAppear = false
                break
            }

            Logger.app.debug("App进入活跃状态: scenePhase .active")
            TrackHelper.shared.event(category: "Lifecycle", action: "Active")

            checkAndRelogin()
            #if os(iOS)
            ActivityManager.shared.autoUpdateActivity()
            BackgroundTaskHelper.shared.cancel()
            #endif
        case .inactive:
            Logger.app.debug("App进入非活跃状态: scenePhase .inactive")
            TrackHelper.shared.event(category: "Lifecycle", action: "Inactive")

            Self.lastBackgroundDate = .now
            #if os(iOS)
            ActivityManager.shared.autoUpdateActivity()
            #endif
        case .background:
            Logger.app.debug("App进入后台状态: scenePhase .background")
            TrackHelper.shared.event(category: "Lifecycle", action: "Background")

            #if os(iOS)
            BackgroundTaskHelper.shared.schedule()
            #endif
        default:
            break
        }
    }

    /// 当App长时间不活跃会到前台后，检查当前学校系统登录状态
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
