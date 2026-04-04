//
//  NotificationDebugViewerView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/24.
//

#if DEBUG
import Foundation
import SwiftUI
import UserNotifications

struct NotificationDebugViewerView: View {
    @State private var pendingRequests: [UNNotificationRequest] = []
    @State private var deliveredNotifications: [UNNotification] = []
    @State private var isLoading = false
    @State private var lastUpdated: Date?

    var body: some View {
        List {
            Section("概览") {
                LabeledContent("Pending") {
                    Text("\(pendingRequests.count)")
                        .monospacedDigit()
                }

                LabeledContent("Delivered") {
                    Text("\(deliveredNotifications.count)")
                        .monospacedDigit()
                }

                if let lastUpdated {
                    LabeledContent("最后刷新") {
                        Text(lastUpdated.formatted(date: .omitted, time: .standard))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Pending通知") {
                if pendingRequests.isEmpty {
                    Text("暂无Pending通知")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pendingRequests, id: \.identifier) { request in
                        pendingRequestRow(request)
                    }
                }
            }

            Section("Delivered通知") {
                if deliveredNotifications.isEmpty {
                    Text("暂无Delivered通知")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(deliveredNotifications.enumerated()), id: \.offset) { item in
                        deliveredNotificationRow(item.element)
                    }
                }
            }
        }
        .navigationTitle("通知查看器")
        .toolbar {
            Button(action: refresh) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)
        }
        .task {
            await loadNotifications()
        }
        .safeRefreshable {
            await loadNotifications()
        }
    }

    private func refresh() {
        Task {
            await loadNotifications()
        }
    }

    @MainActor
    private func loadNotifications() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let center = UNUserNotificationCenter.current()
        let pending = await center.debugPendingNotificationRequests()
        let delivered = await center.debugDeliveredNotifications()

        pendingRequests = pending.sorted { lhs, rhs in
            lhs.identifier.localizedCaseInsensitiveCompare(rhs.identifier) == .orderedAscending
        }
        deliveredNotifications = delivered.sorted { lhs, rhs in
            lhs.date > rhs.date
        }
        lastUpdated = .now
    }

    @ViewBuilder
    private func pendingRequestRow(_ request: UNNotificationRequest) -> some View {
        let content = request.content

        VStack(alignment: .leading, spacing: 6) {
            Text(request.identifier)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text(displayTitle(for: content))
                .font(.headline)

            if !content.subtitle.isEmpty {
                Text(content.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !content.body.isEmpty {
                Text(content.body)
                    .font(.footnote)
            }

            Text(triggerDescription(for: request.trigger))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            if !content.userInfo.isEmpty {
                Text(userInfoDescription(from: content.userInfo))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func deliveredNotificationRow(_ notification: UNNotification) -> some View {
        let request = notification.request
        let content = request.content

        VStack(alignment: .leading, spacing: 6) {
            Text(request.identifier)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text(displayTitle(for: content))
                .font(.headline)

            if !content.subtitle.isEmpty {
                Text(content.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !content.body.isEmpty {
                Text(content.body)
                    .font(.footnote)
            }

            Text("送达时间: \(notification.date.formatted(date: .abbreviated, time: .standard))")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            if !content.userInfo.isEmpty {
                Text(userInfoDescription(from: content.userInfo))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }

    private func displayTitle(for content: UNNotificationContent) -> String {
        content.title.isEmpty ? "<无标题通知>" : content.title
    }

    private func triggerDescription(for trigger: UNNotificationTrigger?) -> String {
        guard let trigger else {
            return "触发器: 立即"
        }

        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            let nextDateText = calendarTrigger.nextTriggerDate()?.formatted(date: .abbreviated, time: .standard) ?? "未知时间"
            return "触发器: 日历 · \(nextDateText)\(calendarTrigger.repeats ? " · 重复" : "")"
        }

        if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return "触发器: 间隔 \(Int(timeIntervalTrigger.timeInterval))s\(timeIntervalTrigger.repeats ? " · 重复" : "")"
        }

        if trigger is UNPushNotificationTrigger {
            return "触发器: 远程推送"
        }

        return "触发器: 未知"
    }

    private func userInfoDescription(from userInfo: [AnyHashable: Any]) -> String {
        let normalized = userInfo.reduce(into: [String: Any]()) { result, item in
            result[String(describing: item.key)] = item.value
        }

        if JSONSerialization.isValidJSONObject(normalized),
            let data = try? JSONSerialization.data(withJSONObject: normalized, options: [.prettyPrinted, .sortedKeys]),
            let string = String(data: data, encoding: .utf8)
        {
            return "userInfo:\n\(string)"
        }

        let lines =
            normalized
            .map { key, value in
                "\(key): \(String(describing: value))"
            }
            .sorted()
            .joined(separator: "\n")
        return "userInfo:\n\(lines)"
    }
}

extension UNUserNotificationCenter {
    fileprivate func debugPendingNotificationRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    fileprivate func debugDeliveredNotifications() async -> [UNNotification] {
        await withCheckedContinuation { continuation in
            getDeliveredNotifications { notifications in
                continuation.resume(returning: notifications)
            }
        }
    }
}
#endif
