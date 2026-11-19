//
//  Router.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class Router {
    var selectedTab: AppTabItem = .overview
    private var isCompact = true

    private var paths: [AppTabItem: [RouteEntry]] = [:]

    subscript(pathFor tab: AppTabItem) -> [RouteEntry] {
        get {
            let path = paths[tab, default: []]
            // 宽屏已经把功能首页作为 tab 根视图。
            if case .feature = tab, path.first == tab.rootRoute {
                return Array(path.dropFirst())
            }
            return path
        }
        set {
            if case .feature = tab {
                let first = paths[tab]?.first
                // 站内从首页进入时保留首页，窄屏直达详情时可以从目标页开始。
                if first == nil || first == tab.rootRoute || newValue.isEmpty {
                    paths[tab] = [tab.rootRoute] + newValue
                    return
                }
            }
            paths[tab] = newValue
        }
    }

    var currentTrackPath: [String] {
        let pagePath = paths[selectedTab]?.last?.path ?? selectedTab.rootRoute.path
        return ["app"] + pagePath.split(separator: "/").map(String.init)
    }

    func open(_ entry: RouteEntry) {
        guard let owner = AppRoutes.tab(for: entry) else { return }

        let tab: AppTabItem
        if isCompact, case .feature = owner {
            tab = .features
        } else {
            tab = owner
        }

        paths[tab] = entry == tab.rootRoute ? [] : [entry]
        selectedTab = tab
    }

    func handleSizeClassChange(toCompact: Bool) {
        guard isCompact != toCompact else { return }
        isCompact = toCompact

        if toCompact, case .feature = selectedTab {
            let path = paths[selectedTab, default: []]
            paths[.features] = path.isEmpty ? [selectedTab.rootRoute] : path
            selectedTab = .features
        } else if !toCompact, selectedTab == .features {
            let path = paths.removeValue(forKey: .features) ?? []
            if let first = path.first, let owner = AppRoutes.tab(for: first), case .feature = owner {
                paths[owner] = path
                selectedTab = owner
            } else {
                selectedTab = .overview
            }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard let entry = AppRoutes.entry(for: url) else { return }
        open(entry)
    }
}
