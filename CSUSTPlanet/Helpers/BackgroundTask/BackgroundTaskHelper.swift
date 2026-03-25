//
//  BackgroundTaskHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

#if os(iOS)

import BackgroundTasks
import Combine
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

    private var cancellables = Set<AnyCancellable>()

    let identifier: String = Constants.backgroundID

    var enabledTaskIdentifiers: Set<String>
    var interval: TimeInterval {
        didSet { MMKVHelper.BackgroundTask.interval = interval }
    }
    let availableIntervals: [TimeInterval] = [
        3 * 60 * 60,
        6 * 60 * 60,
        9 * 60 * 60,
        12 * 60 * 60,
    ]

    var isEnabled: Bool {
        didSet { MMKVHelper.BackgroundTask.isEnabled = isEnabled }
    }

    let tasks: [BackgroundTaskProvider] = [
        GradeBackgroundTask(),
        ElectricityBackgroundTask(),
    ]

    var enabledTasks: [BackgroundTaskProvider] {
        tasks.filter { enabledTaskIdentifiers.contains($0.identifier) }
    }

    private init() {
        enabledTaskIdentifiers = Set(MMKVHelper.BackgroundTask.enabledTaskIdentifiers)
        interval = MMKVHelper.BackgroundTask.interval
        isEnabled = MMKVHelper.BackgroundTask.isEnabled

        register()
        startObservingLifecycle()
    }

    private func register() {
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

    private func startObservingLifecycle() {
        LifecycleManager.shared.events
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .didBecomeActive:
                    self.cancel()
                case .didEnterBackground:
                    self.schedule()
                case .didBecomeInactive:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func schedule() {
        guard MMKVHelper.BackgroundTask.isEnabled else {
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
        MMKVHelper.BackgroundTask.enabledTaskIdentifiers = Array(enabledTaskIdentifiers)
    }
}
#endif

extension MMKVHelper {
    enum BackgroundTask {
        @MMKVStorage(key: "BackgroundTask.enabledTaskIdentifiers", defaultValue: [])
        static var enabledTaskIdentifiers: [String]

        @MMKVStorage(key: "BackgroundTask.isEnabled", defaultValue: false)
        static var isEnabled: Bool

        @MMKVStorage(key: "BackgroundTask.interval", defaultValue: 6 * 60 * 60)
        static var interval: TimeInterval
    }
}
