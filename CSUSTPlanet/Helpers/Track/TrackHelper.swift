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

final class TrackHelper {
    static let shared = TrackHelper()

    private lazy var tracker: MatomoTracker = {
        let dispatcher = URLSessionDispatcher(baseURL: URL(string: Constants.matomoURL)!)
        let queue = MatomoGRDBQueue()
        let logger = MatomoLogger(minLevel: .debug)

        let instance = MatomoTracker(siteId: Constants.matomoSiteID, queue: queue, dispatcher: dispatcher)
        instance.logger = logger

        if let index = Int(Constants.matomoDimensionIDAppVersion),
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            instance.setDimension("\(version) (\(buildNumber))", forIndex: index)
        }

        if let index = Int(Constants.matomoDimensionIDAppEnvironment) {
            instance.setDimension(EnvironmentUtil.environment.rawValue, forIndex: index)
        }

        instance.dispatchInterval = 30

        Logger.trackHelper.debug("初始化 MatomoTracker 完成")

        if let currentUserId = MMKVHelper.Track.userId {
            instance.userId = currentUserId
            Logger.trackHelper.debug("初始化时同步用户ID: \(currentUserId)")
        }
        return instance
    }()

    func views(path: [String]) {
        tracker.track(view: path)
        Logger.trackHelper.debug("跟踪页面: \(path.joined(separator: "/"), privacy: .public)")
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
        Logger.trackHelper.debug("更新用户是否拒绝跟踪: \(isOptedOut, privacy: .public)")
    }
}

extension os.Logger {
    static let trackHelper = Logger(appCategory: "TrackHelper")
}

extension MMKVHelper {
    enum Track {
        @MMKVOptionalStorage(key: "GlobalVars.userId")
        static var userId: String?
    }
}
