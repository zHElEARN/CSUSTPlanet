//
//  NotificationManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

#if os(iOS) || os(macOS)

import Foundation
import OSLog
import SwiftUI
import UserNotifications
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private var token: Data?
    private var tokenContinuation: CheckedContinuation<Data?, Never>? = nil

    private var isUpdatingNotification = false

    // MARK: - State

    var hasNotificationAuthorization = false

    var isNotificationEnabled: Bool {
        didSet {
            if !hasNotificationAuthorization && isNotificationEnabled {
                isNotificationEnabled = false
                return
            }
            MMKVHelper.shared.isNotificationEnabled = isNotificationEnabled
            updateNotification()
        }
    }

    private init() {
        isNotificationEnabled = MMKVHelper.shared.isNotificationEnabled
    }

    func refreshAuthorizationStatus() async {
        let result = await hasAuthorization()
        withAnimation {
            hasNotificationAuthorization = result
            if !result {
                isNotificationEnabled = false
            }
        }
    }

    private func updateNotification() {
        guard !isUpdatingNotification else { return }
        guard isNotificationEnabled else { return }

        Task {
            isUpdatingNotification = true
            defer { isUpdatingNotification = false }

            guard await getToken() != nil else {
                return
            }
        }
    }

    func getToken() async -> Data? {
        if let token = token { return token }

        Logger.notificationManager.debug("开始向系统请求设备令牌")
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        do {
            guard try await UNUserNotificationCenter.current().requestAuthorization(options: options) else {
                Logger.notificationManager.error("用户拒绝了通知权限")
                return nil
            }
        } catch {
            Logger.notificationManager.error("请求通知权限失败: \(error.localizedDescription)")
            return nil
        }

        #if os(iOS)
        UIApplication.shared.registerForRemoteNotifications()
        #elseif os(macOS)
        NSApplication.shared.registerForRemoteNotifications()
        #endif

        return await withCheckedContinuation { continuation in
            self.tokenContinuation = continuation
            Task {
                try? await Task.sleep(for: .seconds(10))
                if let continuation = self.tokenContinuation {
                    Logger.notificationManager.error("获取设备令牌超时")
                    self.tokenContinuation = nil
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func hasAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func handleNotificationRegistration(token: Data?, error: Error?) {
        guard let tokenContinuation = tokenContinuation else { return }
        guard let token = token else {
            Logger.notificationManager.error("无法获取到通知令牌")
            self.tokenContinuation = nil
            tokenContinuation.resume(returning: nil)
            return
        }
        Logger.notificationManager.debug("获取到通知令牌: \(token.hexString)")
        self.tokenContinuation = nil
        tokenContinuation.resume(returning: token)
        self.token = token
    }
}

extension Data {
    var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
#endif
