//
//  NotificationManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/15.
//

import Combine
import Foundation
import SwiftUI
import UserNotifications

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum NotificationManagerError: Error {
    case tokenTimeout
    case registrationFailed(Error)
}

enum NotificationPermissionStatus: String {
    case authorized = "已开启"
    case denied = "已关闭"
    case requestable = "未设置"
}

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private var cancellables = Set<AnyCancellable>()

    private var tokenContinuation: CheckedContinuation<String, Error>?
    private var token: String?

    var permissionStatus: NotificationPermissionStatus?

    private init() {
        startObservingLifecycle()

        Task {
            await updatePermissionStatus()
        }
        Task {
            try? await requestToken()
        }
    }

    private func startObservingLifecycle() {
        LifecycleManager.shared.events
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .didBecomeActive:
                    Task {
                        await self.updatePermissionStatus()
                    }
                    break
                case .didBecomeInactive, .didEnterBackground:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func requestPermission() async throws -> Bool {
        let isGranted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        await updatePermissionStatus()
        return isGranted
    }

    func updatePermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        let status: NotificationPermissionStatus
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = .authorized
        case .denied:
            status = .denied
        case .notDetermined:
            status = .requestable
        @unknown default:
            status = .requestable
        }

        withAnimation { permissionStatus = status }
    }

    func requestToken() async throws -> String {
        if let token = token { return token }

        PlatformApplication.shared.registerForRemoteNotifications()

        return try await withCheckedThrowingContinuation { continuation in
            self.tokenContinuation?.resume(throwing: CancellationError())
            self.tokenContinuation = continuation

            Task {
                try? await Task.sleep(for: .seconds(10))
                if let pendingContinuation = self.tokenContinuation {
                    pendingContinuation.resume(throwing: NotificationManagerError.tokenTimeout)
                    self.tokenContinuation = nil
                }
            }
        }
    }
}

// MARK: - Delegate Callback

extension NotificationManager {
    func didRegisterForRemoteNotifications(with token: Data) {
        self.token = token.hexString
        tokenContinuation?.resume(returning: token.hexString)
        tokenContinuation = nil
    }

    func didFailToRegisterForRemoteNotifications(with error: Error) {
        tokenContinuation?.resume(throwing: NotificationManagerError.registrationFailed(error))
        tokenContinuation = nil
    }
}

extension Data {
    fileprivate var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
