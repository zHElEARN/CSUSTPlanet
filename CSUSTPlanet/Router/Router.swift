//
//  Router.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class Router {
    var selectedTab: AppTabItem = .overview
    var isCompact: Bool = true

    private var paths: [AppTabItem: [AppRoute]] = [:]

    subscript(pathFor tab: AppTabItem) -> [AppRoute] {
        get { paths[tab, default: []] }
        set { paths[tab] = newValue }
    }

    var currentTrackPath: [String] {
        var path = ["App", selectedTab.trackSegment]
        let activeStack = paths[selectedTab, default: []]
        path.append(contentsOf: activeStack.map(\.trackSegment))
        return path
    }

    func deepLinkToOverview(path: [AppRoute] = []) {
        selectedTab = .overview
        DispatchQueue.main.async {
            self.paths[.overview] = path
        }
    }

    func deepLinkToProfile(path: [AppRoute] = []) {
        selectedTab = .profile
        DispatchQueue.main.async {
            self.paths[.profile] = path
        }
    }

    func deepLinkTo(feature: FeatureTabID, path: [AppRoute] = []) {
        if isCompact {
            selectedTab = .features
            DispatchQueue.main.async {
                self.paths[.features] = [feature.rootRoute] + path
            }
        } else {
            let targetTab = AppTabItem.feature(feature)
            selectedTab = targetTab
            DispatchQueue.main.async {
                self.paths[targetTab] = path
            }
        }
    }

    func deepLinkToFeaturesRoot() {
        if isCompact {
            selectedTab = .features
            DispatchQueue.main.async {
                self.paths[.features] = []
            }
        } else {
            selectedTab = .overview
        }
    }

    func handleSizeClassChange(toCompact: Bool) {
        if toCompact {
            // Regular -> Compact，合并独立功能栈到 Features
            if case .feature(let feature) = selectedTab {
                selectedTab = .features
                let independentPath = paths[.feature(feature), default: []]
                paths[.features] = [feature.rootRoute] + independentPath
            }
        } else {
            // Compact -> Regular，从 Features 栈拆回独立功能栈
            if selectedTab == .features {
                let compactPath = paths[.features, default: []]

                if let rootAppRoute = compactPath.first,
                    let matchedFeature = FeatureTabID.allCases.first(where: { $0.rootRoute == rootAppRoute })
                {
                    let targetTab = AppTabItem.feature(matchedFeature)
                    selectedTab = targetTab
                    paths[targetTab] = Array(compactPath.dropFirst())
                } else {
                    selectedTab = .overview
                }

                paths[.features] = []
            }
        }
    }
}

struct AppRouteDestinationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: AppRoute.self) { route in
                route.destinationView
            }
    }
}

extension View {
    func withAppRouter() -> some View {
        modifier(AppRouteDestinationModifier())
    }
}
