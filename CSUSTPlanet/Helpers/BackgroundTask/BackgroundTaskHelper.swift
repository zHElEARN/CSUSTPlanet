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
    var title: String { get }
    var description: String { get }

    func perform() async -> Bool
}

// MARK: - BackgroundTaskHelper

@Observable
@MainActor
final class BackgroundTaskHelper {
    static let shared = BackgroundTaskHelper()

    let identifier: String = Constants.backgroundID

    var enabledTaskIdentifiers: Set<String>
    var interval: TimeInterval
    let availableIntervals: [TimeInterval] = [
        3 * 60 * 60,
        6 * 60 * 60,
        9 * 60 * 60,
        12 * 60 * 60,
    ]

    var isEnabled: Bool {
        didSet {
            MMKVHelper.shared.backgroundTaskIsEnabled = isEnabled
        }
    }

    private init() {
        enabledTaskIdentifiers = Set(MMKVHelper.shared.backgroundTaskEnabledTaskIdentifiers)
        interval = MMKVHelper.shared.backgroundTaskInterval

        isEnabled = MMKVHelper.shared.backgroundTaskIsEnabled
    }

    let tasks: [BackgroundTaskProvider] = [
        GradeBackgroundTask(),
        ElectricityBackgroundTask(),
    ]

    var enabledTasks: [BackgroundTaskProvider] {
        tasks.filter { enabledTaskIdentifiers.contains($0.identifier) }
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            Logger.backgroundTaskHelper.debug("开始执行后台任务")
            self.schedule()

            let workTask = Task {
                let providers = self.enabledTasks
                guard !providers.isEmpty else {
                    Logger.backgroundTaskHelper.debug("没有启用的任务")
                    task.setTaskCompleted(success: true)
                    return
                }

                let overallSuccess = await withTaskGroup(of: Bool.self) { group in
                    for provider in providers {
                        group.addTask {
                            return await provider.perform()
                        }
                    }

                    var anySuccess = false
                    for await result in group {
                        if result {
                            anySuccess = true
                        }
                    }

                    return anySuccess
                }

                task.setTaskCompleted(success: overallSuccess)
            }

            task.expirationHandler = {
                Logger.backgroundTaskHelper.warning("统一后台任务即将超时，正在取消所有子任务")
                workTask.cancel()
                task.setTaskCompleted(success: false)
            }
        }
        Logger.backgroundTaskHelper.debug("注册后台任务成功")
    }

    func schedule() {
        guard MMKVHelper.shared.backgroundTaskIsEnabled else {
            Logger.backgroundTaskHelper.debug("未开启后台自动更新，跳过后台任务调度")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.backgroundTaskHelper.debug("调度后台任务成功: \(self.identifier)")
        } catch {
            Logger.backgroundTaskHelper.error("调度后台任务失败: \(error)")
        }
    }

    func cancel() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
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
}
#endif
