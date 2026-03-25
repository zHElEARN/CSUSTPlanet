//
//  TrackHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/30.
//

import Combine
import CryptoKit
import MatomoTracker
import OSLog

@MainActor
final class TrackHelper {
    static let shared = TrackHelper()

    private var cancellables = Set<AnyCancellable>()

    private init() {
        startObservingLifecycle()
    }

    private func startObservingLifecycle() {
        LifecycleManager.shared.events
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .didBecomeActive:
                    self.event(category: "Lifecycle", action: "Active")
                case .didBecomeInactive:
                    self.event(category: "Lifecycle", action: "Inactive")
                case .didEnterBackground:
                    self.event(category: "Lifecycle", action: "Background")
                }
            }
            .store(in: &self.cancellables)
    }

    private lazy var tracker: MatomoTracker = {
        let instance = MatomoTracker(siteId: Constants.matomoSiteID, baseURL: URL(string: Constants.matomoURL)!)
        #if DEBUG
        instance.logger = DefaultLogger(minLevel: .debug)
        #endif
        if let index = Int(Constants.matomoDimensionIDAppFullVersion),
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            instance.setDimension("\(version) (\(buildNumber))", forIndex: index)
        }
        instance.dispatchInterval = 60
        Logger.trackHelper.debug("初始化 MatomoTracker 完成")
        if let currentUserId = MMKVHelper.shared.userId {
            instance.userId = currentUserId
            Logger.trackHelper.debug("初始化时同步用户ID: \(currentUserId)")
        }
        return instance
    }()

    func views(path: [String]) {
        tracker.track(view: path)
        Logger.trackHelper.debug("跟踪页面: \(path.joined(separator: "/"))")
    }

    func event(category: String, action: String, name: String? = nil, value: NSNumber? = nil, path: [String]? = nil) {
        let virtualURL = path.flatMap { URL(string: "http://\(Constants.appBundleID.lowercased())/" + $0.joined(separator: "/")) }
        tracker.track(
            eventWithCategory: category,
            action: action,
            name: name,
            number: value,
            url: virtualURL
        )
        Logger.trackHelper.debug("跟踪事件: \(category) - \(action) - \(name ?? "nil") - \(String(describing: value)) - \(String(describing: virtualURL))")
    }

    func flush() {
        tracker.dispatch()
        Logger.trackHelper.debug("刷新 MatomoTracker")
    }

    func updateUserID(_ id: String?) {
        guard let id = id, !id.isEmpty else {
            tracker.userId = nil
            Logger.trackHelper.debug("用户ID已清空")
            return
        }
        tracker.userId = id
        Logger.trackHelper.debug("用户ID已更新: \(id)")
    }

    func updateIsOptedOut(_ isOptedOut: Bool) {
        tracker.isOptedOut = isOptedOut
        Logger.trackHelper.debug("更新用户是否拒绝跟踪: \(isOptedOut)")
    }
}
