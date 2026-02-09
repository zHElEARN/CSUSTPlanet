//
//  AppDelegate.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Foundation
import MMKV
import OSLog
import TipKit
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    private var isFirstAppear = true
    private var lastBackgroundDate: Date?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        setupTipKit()

        ActivityHelper.shared.setup()
        NotificationManager.shared.setup()
        TrackHelper.shared.setup()

        return true
    }

    // MARK: - Setup Methods

    func setupTipKit() {
        #if DEBUG
            try? Tips.resetDatastore()
        #endif
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
        ])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Remote Notification

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.handleNotificationRegistration(token: deviceToken, error: nil)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        NotificationManager.shared.handleNotificationRegistration(token: nil, error: error)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
