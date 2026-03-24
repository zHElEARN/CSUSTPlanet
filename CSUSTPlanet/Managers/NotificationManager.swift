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
    enum NotificationToggleResult: Equatable {
        case enabled
        case disabled
        case requiresSystemSettings
    }

    static let shared = NotificationManager()

    private var token: Data?
    private var tokenContinuation: CheckedContinuation<Data?, Never>? = nil
    private var tokenRequestTask: Task<Data?, Never>?

    // MARK: - State

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isNotificationEnabled: Bool
    private(set) var isHandlingNotificationToggle = false

    private init() {
        isNotificationEnabled = MMKVHelper.shared.isNotificationEnabled
    }

    func refreshAuthorizationStatus() async {
        let status = await currentAuthorizationStatus()
        Logger.notificationManager.debug("刷新通知权限状态: \(status.rawValue)")
        authorizationStatus = status

        if !isAuthorizationGranted(status) && isNotificationEnabled {
            await disableNotifications()
        }
    }

    func handleAppLaunch() async {
        Logger.notificationManager.debug("处理应用启动时的通知状态同步")
        await refreshAuthorizationStatus()
        await ensureTokenForEnabledNotifications()
    }

    func handleAppDidBecomeActive() async {
        Logger.notificationManager.debug("处理应用恢复活跃时的通知状态同步")
        await refreshAuthorizationStatus()
        await ensureTokenForEnabledNotifications()
    }

    func setNotificationEnabled(_ enabled: Bool) async -> NotificationToggleResult {
        guard !isHandlingNotificationToggle else {
            return isNotificationEnabled ? .enabled : .disabled
        }

        isHandlingNotificationToggle = true
        defer { isHandlingNotificationToggle = false }

        Logger.notificationManager.debug("用户尝试\(enabled ? "开启" : "关闭")应用内通知")

        if !enabled {
            await disableNotifications()
            return .disabled
        }

        let status = await currentAuthorizationStatus()
        authorizationStatus = status

        switch status {
        case .notDetermined:
            Logger.notificationManager.debug("通知权限尚未决定，开始请求系统授权")
            let granted = await requestAuthorization()
            await refreshAuthorizationStatus()

            guard granted, isAuthorizationGranted(authorizationStatus) else {
                Logger.notificationManager.debug("通知权限请求未通过，需要用户前往系统设置处理")
                return .requiresSystemSettings
            }
        default:
            guard isAuthorizationGranted(status) else {
                Logger.notificationManager.debug("系统通知权限已被拒绝，阻止开启应用内通知")
                return .requiresSystemSettings
            }
        }

        persistNotificationEnabled(true)

        if let token = await getToken() {
            await syncNotificationSubscription(token: token)
        }

        return .enabled
    }

    func getToken() async -> Data? {
        if let token { return token }
        if let tokenRequestTask { return await tokenRequestTask.value }

        let task = Task { @MainActor [weak self] () -> Data? in
            guard let self else { return nil }

            let status = await self.currentAuthorizationStatus()
            self.authorizationStatus = status

            guard self.isNotificationEnabled, self.isAuthorizationGranted(status) else {
                return nil
            }

            Logger.notificationManager.debug("开始向系统请求设备令牌")
            return await withCheckedContinuation { continuation in
                self.tokenContinuation = continuation

                #if os(iOS)
                UIApplication.shared.registerForRemoteNotifications()
                #elseif os(macOS)
                NSApplication.shared.registerForRemoteNotifications()
                #endif

                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .seconds(10))
                    guard let self, let continuation = self.tokenContinuation else { return }

                    Logger.notificationManager.error("获取设备令牌超时")
                    self.tokenContinuation = nil
                    continuation.resume(returning: nil)
                }
            }
        }

        tokenRequestTask = task
        let result = await task.value
        tokenRequestTask = nil
        return result
    }

    func handleNotificationDisabled(token: Data?) async {
        if let token {
            Logger.notificationManager.debug("应用内通知已关闭，预留清理副作用回调被调用，token: \(token.hexString)")
        } else {
            Logger.notificationManager.debug("应用内通知已关闭，预留清理副作用回调被调用，当前无可用 token")
        }
    }

    func syncNotificationSubscription(token: Data) async {
        Logger.notificationManager.debug("预留通知订阅同步回调被调用，token: \(token.hexString)")
    }

    private func ensureTokenForEnabledNotifications() async {
        guard isNotificationEnabled else { return }
        guard isAuthorizationGranted(authorizationStatus) else { return }

        Logger.notificationManager.debug("应用内通知已开启且系统已授权，确保设备 token 可用")
        _ = await getToken()
    }

    private func disableNotifications() async {
        let currentToken = token
        Logger.notificationManager.debug("开始关闭应用内通知并清理相关副作用")
        persistNotificationEnabled(false)
        await handleNotificationDisabled(token: currentToken)
    }

    private func persistNotificationEnabled(_ enabled: Bool) {
        Logger.notificationManager.debug("持久化应用内通知开关状态: \(enabled)")
        isNotificationEnabled = enabled
        MMKVHelper.shared.isNotificationEnabled = enabled
    }

    private func requestAuthorization() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            Logger.notificationManager.debug("系统通知授权请求结果: \(granted)")
            return granted
        } catch {
            Logger.notificationManager.error("请求通知权限失败: \(error.localizedDescription)")
            return false
        }
    }

    private func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    private func isAuthorizationGranted(_ status: UNAuthorizationStatus) -> Bool {
        status == .authorized || status == .provisional
    }

    func handleNotificationRegistration(token: Data?, error: Error?) {
        if let error {
            Logger.notificationManager.error("注册远程通知失败: \(error.localizedDescription)")
        }

        if let token {
            Logger.notificationManager.debug("获取到通知令牌: \(token.hexString)")
            self.token = token
        }

        guard let tokenContinuation else { return }
        self.tokenContinuation = nil

        guard let token else {
            Logger.notificationManager.error("无法获取到通知令牌")
            tokenContinuation.resume(returning: nil)
            return
        }

        tokenContinuation.resume(returning: token)
    }
}

extension Data {
    var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
#endif
