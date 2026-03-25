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

            Task { await NotificationManager.shared.handleAppDidBecomeActive() }
        case .inactive:
            break
        case .background:
            break
        default:
            break
        }
    }
}
