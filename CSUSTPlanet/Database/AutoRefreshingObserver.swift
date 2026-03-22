//
//  AutoRefreshingObserver.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/22.
//

import Foundation
import GRDB

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class AutoRefreshingObserver {
    private var dbCancellable: (any DatabaseCancellable)?
    private let startBlock: () -> (any DatabaseCancellable)?
    private var notificationTokens: [Any] = []

    init(startBlock: @escaping () -> (any DatabaseCancellable)?) {
        self.startBlock = startBlock

        restart()

        let dataChangeObserverToken = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("CSUSTPlanetDBChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restart()
        }
        notificationTokens.append(dataChangeObserverToken)

        #if canImport(UIKit)
        let lifecycleNotification: Notification.Name? = UIApplication.willEnterForegroundNotification
        #elseif canImport(AppKit)
        let lifecycleNotification: Notification.Name? = NSApplication.willBecomeActiveNotification
        #else
        let lifecycleNotification: Notification.Name? = nil
        #endif

        if let lifecycleNotification {
            let lifecycleObserverToken = NotificationCenter.default.addObserver(
                forName: lifecycleNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.restart()
            }
            notificationTokens.append(lifecycleObserverToken)
        }
    }

    private func restart() {
        dbCancellable?.cancel()
        dbCancellable = startBlock()
    }

    deinit {
        dbCancellable?.cancel()
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
