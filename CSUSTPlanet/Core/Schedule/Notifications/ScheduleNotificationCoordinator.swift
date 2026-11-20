import Combine
import Foundation
import OSLog
import Observation

@MainActor
@Observable
final class ScheduleNotificationCoordinator {
    static let shared = ScheduleNotificationCoordinator()

    private static let logger = Logger(appCategory: "ScheduleNotifications")
    // 在 iOS 已知的历史上限内保留余量，并计入其他功能的待发通知。
    private static let pendingNotificationBudget = 60

    private(set) var isEnabled = MMKVHelper.ScheduleNotifications.isEnabled
    private var rules = MMKVHelper.ScheduleNotifications.rules

    @ObservationIgnored private var events: [ScheduleEvent]?
    @ObservationIgnored private var scheduleSubscription: AnyCancellable?
    @ObservationIgnored private var permissionSubscription: AnyCancellable?
    @ObservationIgnored private var lifecycleSubscription: AnyCancellable?
    @ObservationIgnored private var syncRequested = false
    @ObservationIgnored private var isSyncing = false

    private init() {
        lifecycleSubscription = LifecycleManager.shared.events.sink { [weak self] event in
            guard case .didBecomeActive = event else { return }
            self?.requestSync()
        }

        if isEnabled {
            observeSchedule()
        }
        requestSync()
    }

    func rule(for kind: ScheduleEventKind) -> ScheduleNotificationRule {
        rules[kind] ?? .defaults(for: kind)
    }

    func setRule(_ rule: ScheduleNotificationRule, for kind: ScheduleEventKind) {
        guard rule != self.rule(for: kind) else { return }
        rules[kind] = rule
        MMKVHelper.ScheduleNotifications.rules = rules
        if isEnabled {
            requestSync()
        }
    }

    func setEnabledByUser(_ enabled: Bool) async throws -> Bool {
        guard enabled != isEnabled else { return true }
        guard enabled else {
            disable()
            return true
        }

        let manager = NotificationManager.shared
        await manager.updatePermissionStatus()
        if manager.permissionStatus == .requestable {
            _ = try await manager.requestPermission()
        }
        guard manager.permissionStatus == .authorized else { return false }

        isEnabled = true
        MMKVHelper.ScheduleNotifications.isEnabled = true
        observeSchedule()
        return true
    }

    private func observeSchedule() {
        if permissionSubscription == nil {
            permissionSubscription = NotificationManager.shared.permissionStatusPublisher
                .compactMap { $0 }
                .removeDuplicates()
                .sink { [weak self] status in
                    guard let self, self.isEnabled, status != .authorized else { return }
                    self.disable()
                }
        }

        guard isEnabled else { return }
        scheduleSubscription = ScheduleEventStore.shared.eventsPublisher.sink { [weak self] events in
            self?.events = events
            self?.requestSync()
        }
    }

    private func disable() {
        isEnabled = false
        MMKVHelper.ScheduleNotifications.isEnabled = false
        scheduleSubscription?.cancel()
        scheduleSubscription = nil
        events = nil
        requestSync()
    }

    private func requestSync() {
        syncRequested = true
        guard !isSyncing else { return }
        isSyncing = true

        Task {
            while syncRequested {
                syncRequested = false
                await syncNotifications()
            }
            isSyncing = false
        }
    }

    private func syncNotifications() async {
        guard isEnabled else {
            await NotificationManager.clearLocalNotifications(prefix: ScheduleNotificationPlan.prefix)
            return
        }

        let manager = NotificationManager.shared
        await manager.updatePermissionStatus()
        guard isEnabled, let events else { return }

        let drafts = ScheduleNotificationPlan.makeDrafts(events: events, rules: rules, now: .now)
        do {
            try await manager.syncLocalNotifications(
                prefix: ScheduleNotificationPlan.prefix,
                drafts: drafts,
                maxPendingCount: Self.pendingNotificationBudget
            )
        } catch {
            Self.logger.error("日程通知同步失败: \(error.localizedDescription)")
        }
    }
}
