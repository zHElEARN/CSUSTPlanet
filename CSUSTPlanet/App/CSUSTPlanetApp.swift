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
        SentrySDK.start { options in
            options.dsn = Constants.sentryDSN
            options.environment = EnvironmentUtil.environment.rawValue
        }

        _ = DatabaseManager.shared
        _ = TrackHelper.shared

        #if os(iOS)
        _ = BackgroundTaskHelper.shared
        _ = ActivityManager.shared
        #endif

        Task { await NotificationManager.shared.handleAppLaunch() }
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
        .onChange(of: scenePhase) { _, newPhase in handleScenePhaseChange(to: newPhase) }
    }

    private func handleScenePhaseChange(to phase: ScenePhase) {
        LifecycleManager.shared.publishScenePhaseChange(to: phase)

        switch phase {
        case .active:
            // 首次启动时不处理
            if Self.isFirstAppear {
                Self.isFirstAppear = false
                break
            }

            checkAndRelogin()
            Task { await NotificationManager.shared.handleAppDidBecomeActive() }
        case .inactive:
            Self.lastBackgroundDate = .now
        case .background:
            break
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
