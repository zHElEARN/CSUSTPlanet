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

@main
struct CSUSTPlanetApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = DatabaseManager.shared
        _ = TrackHelper.shared
        _ = NotificationManager.shared
        _ = PlanetAuthService.shared
        _ = PlanetTaskService.shared
        _ = GlobalManager.shared

        #if os(iOS)
        _ = BackgroundTaskHelper.shared
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
        .onChange(of: scenePhase) { _, newPhase in LifecycleManager.shared.publishScenePhaseChange(to: newPhase) }
    }
}
