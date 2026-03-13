//
//  BackgroundTaskHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

#if os(iOS)

import BackgroundTasks
import Foundation
import OSLog

// MARK: - BackgroundTaskProvider

protocol BackgroundTaskProvider {
    var identifier: String { get }

    var defaultInterval: TimeInterval { get }
    var availableIntervals: [TimeInterval] { get }

    var title: String { get }
    var description: String { get }

    func handle(task: BGAppRefreshTask)
}

// MARK: - BackgroundTaskHelper

@Observable
@MainActor
final class BackgroundTaskHelper {
    static let shared = BackgroundTaskHelper()

    var enabledTaskIdentifiers: Set<String>
    var taskIntervals: [String: TimeInterval]

    private init() {
        enabledTaskIdentifiers = Set(MMKVHelper.shared.backgroundTaskEnabledTaskIdentifiers)
        taskIntervals = MMKVHelper.shared.backgroundTaskIntervals
    }

    let tasks: [BackgroundTaskProvider] = [
        GradeBackgroundTask(),
        ElectricityBackgroundTask(),
    ]

    var enabledTasks: [BackgroundTaskProvider] {
        tasks.filter { enabledTaskIdentifiers.contains($0.identifier) }
    }

    func registerAllTasks() {
        for provider in tasks {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: provider.identifier, using: nil) { task in
                guard let task = task as? BGAppRefreshTask else { return }
                self.schedule(provider: provider)
                provider.handle(task: task)
            }
        }
        Logger.backgroundTaskHelper.debug("注册全部后台任务成功")
    }

    func schedule(provider: BackgroundTaskProvider) {
        guard MMKVHelper.shared.backgroundTaskIsEnabled else {
            Logger.backgroundTaskHelper.debug("未开启后台自动更新，跳过调度: \(provider.identifier)")
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: provider.identifier)

        let currentInterval = self.interval(for: provider)
        request.earliestBeginDate = Date(timeIntervalSinceNow: currentInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.backgroundTaskHelper.debug("调度后台任务成功: \(provider.identifier)")
        } catch {
            Logger.backgroundTaskHelper.error("调度后台任务失败: \(error)")
        }
    }

    func scheduleAllTasks() {
        guard MMKVHelper.shared.backgroundTaskIsEnabled else {
            Logger.backgroundTaskHelper.debug("未开启后台自动更新，跳过调度全部任务")
            return
        }
        enabledTasks.forEach { schedule(provider: $0) }
        Logger.backgroundTaskHelper.debug("调度全部后台任务成功")
    }

    func cancel(provider: BackgroundTaskProvider) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: provider.identifier)
        Logger.backgroundTaskHelper.debug("取消后台任务: \(provider.identifier)")
    }

    func cancelAllTasks() {
        enabledTasks.forEach { cancel(provider: $0) }
        Logger.backgroundTaskHelper.debug("取消全部后台任务")
    }

    func toggleTask(_ provider: BackgroundTaskProvider) {
        if enabledTaskIdentifiers.contains(provider.identifier) {
            enabledTaskIdentifiers.remove(provider.identifier)
        } else {
            enabledTaskIdentifiers.insert(provider.identifier)
        }
        MMKVHelper.shared.backgroundTaskEnabledTaskIdentifiers = Array(enabledTaskIdentifiers)
    }

    func interval(for provider: BackgroundTaskProvider) -> TimeInterval {
        return taskIntervals[provider.identifier] ?? provider.defaultInterval
    }

    func setInterval(_ interval: TimeInterval, for provider: BackgroundTaskProvider) {
        taskIntervals[provider.identifier] = interval
        MMKVHelper.shared.backgroundTaskIntervals = taskIntervals
    }
}
#endif
