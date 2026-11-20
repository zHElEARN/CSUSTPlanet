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

enum NotificationPermissionStatus: String {
    case authorized = "已开启"
    case denied = "已关闭"
    case requestable = "未设置"
}

struct LocalNotificationDraft {
    let identifier: String
    let threadIdentifier: String
    let title: String
    let subtitle: String
    let body: String
    let triggerDate: Date
    let userInfo: [AnyHashable: Any]
}

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    private var cancellables = Set<AnyCancellable>()

    private var permissionStatusSubject = CurrentValueSubject<NotificationPermissionStatus?, Never>(nil)
    private(set) var permissionStatus: NotificationPermissionStatus? {
        didSet {
            permissionStatusSubject.send(permissionStatus)
        }
    }
    var permissionStatusPublisher: AnyPublisher<NotificationPermissionStatus?, Never> {
        permissionStatusSubject.eraseToAnyPublisher()
    }

    private init() {
        startObservingLifecycle()

        Task {
            await updatePermissionStatus()
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
        let isGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await updatePermissionStatus()
        return isGranted
    }

    func updatePermissionStatus() async {
        let settings = await center.notificationSettings()

        let status: NotificationPermissionStatus
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            status = .authorized
        case .denied:
            status = .denied
            center.removeAllPendingNotificationRequests()
        case .notDetermined:
            status = .requestable
        @unknown default:
            status = .requestable
        }

        withAnimation { permissionStatus = status }
    }

    func openAppNotificationSettings() {
        #if os(iOS)
        if let url = URL(string: PlatformApplication.openNotificationSettingsURLString),
            PlatformApplication.shared.canOpenURL(url)
        {
            PlatformApplication.shared.open(url)
        }
        #elseif os(macOS)
        let settingsURL = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        if let url = URL(string: settingsURL) {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

// MARK: - Local Notification

extension NotificationManager {
    func syncLocalNotifications(prefix: String, drafts: [LocalNotificationDraft], maxPendingCount: Int) async throws {
        let pendingRequests = await center.pendingNotificationRequests()
        let managedRequests = pendingRequests.filter { $0.identifier.hasPrefix(prefix) }
        let pendingByID = Dictionary(uniqueKeysWithValues: managedRequests.map { ($0.identifier, $0) })

        let otherPendingCount = pendingRequests.count - managedRequests.count
        let availableSlots = max(0, maxPendingCount - otherPendingCount)
        let now = Date.now
        let desired = Array(drafts.lazy.filter { $0.triggerDate > now }.prefix(availableSlots))
        let desiredIDs = Set(desired.map(\.identifier))
        let obsoleteIDs = managedRequests.map(\.identifier).filter { !desiredIDs.contains($0) }
        if !obsoleteIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: obsoleteIDs)
        }

        var firstError: Error?
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        for draft in desired where draft.triggerDate > .now {
            let dateComponents = calendar.dateComponents(
                [.timeZone, .year, .month, .day, .hour, .minute, .second],
                from: draft.triggerDate
            )
            let existing = pendingByID[draft.identifier]
            if let existing, matches(existing, draft: draft, dateComponents: dateComponents) {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = draft.title
            content.subtitle = draft.subtitle
            content.body = draft.body
            content.sound = .default
            content.threadIdentifier = draft.threadIdentifier
            content.userInfo = draft.userInfo

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: draft.identifier, content: content, trigger: trigger)
            do {
                try await center.add(request)
            } catch {
                if existing != nil {
                    center.removePendingNotificationRequests(withIdentifiers: [draft.identifier])
                }
                firstError = firstError ?? error
            }
        }

        if let firstError {
            throw firstError
        }
    }

    private func matches(_ request: UNNotificationRequest, draft: LocalNotificationDraft, dateComponents: DateComponents) -> Bool {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
            !trigger.repeats, trigger.dateComponents == dateComponents
        else { return false }

        let content = request.content
        return content.title == draft.title
            && content.subtitle == draft.subtitle
            && content.body == draft.body
            && content.threadIdentifier == draft.threadIdentifier
            && (content.userInfo as NSDictionary).isEqual(to: draft.userInfo)
    }

    static func clearLocalNotifications(prefix: String) async {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()
        let pendingIdentifiers =
            pendingRequests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        if !pendingIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)
        }
    }
}

extension Data {
    fileprivate var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
