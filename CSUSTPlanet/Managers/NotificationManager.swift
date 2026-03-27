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

    private var tokenContinuation: CheckedContinuation<Void, Error>?
    private var tokenSubject = CurrentValueSubject<String?, Never>(nil)
    private(set) var token: String? {
        didSet {
            tokenSubject.send(token)
        }
    }
    var tokenPublisher: AnyPublisher<String?, Never> {
        tokenSubject.eraseToAnyPublisher()
    }

    private var permissionStatusSubject = CurrentValueSubject<NotificationPermissionStatus?, Never>(nil)
    private(set) var permissionStatus: NotificationPermissionStatus? {
        didSet {
            permissionStatusSubject.send(permissionStatus)
        }
    }
    var permissionStatusPublisher: AnyPublisher<NotificationPermissionStatus?, Never> {
        permissionStatusSubject.eraseToAnyPublisher()
    }

    private var isUpdatingToken = false

    private init() {
        startObservingLifecycle()

        Task {
            await updatePermissionStatus()
        }
        Task {
            try? await updateToken()
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

    func updateToken() async throws {
        guard self.token == nil else { return }

        guard !isUpdatingToken else { return }
        isUpdatingToken = true
        defer { isUpdatingToken = false }

        PlatformApplication.shared.registerForRemoteNotifications()

        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
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
}

// MARK: - Delegate Callback

extension NotificationManager {
    func didRegisterForRemoteNotifications(with token: Data) {
        self.token = token.hexString
        tokenContinuation?.resume(returning: ())
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
