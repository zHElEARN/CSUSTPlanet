//
//  Router.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import CSUSTKit
import Foundation
import GRDB
import SwiftUI

protocol RouteNode {
    var routePath: [String] { get }
}

extension RouteNode {
    var routePath: [String] {
        var names: [String] = []
        var current: Any = self

        while let name = Self.caseName(of: current) {
            names.append(name)
            guard let payload = Self.payload(of: current),
                let next = Self.routePayload(in: payload)
            else { break }
            current = next
        }

        return names
    }

    private static func caseName(of value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        if let label = mirror.children.first?.label {
            return label
        }
        guard mirror.displayStyle == .enum else { return nil }
        return String(describing: value)
    }

    private static func payload(of value: Any) -> Any? {
        Mirror(reflecting: value).children.first?.value
    }

    private static func routePayload(in payload: Any) -> Any? {
        switch Mirror(reflecting: payload).displayStyle {
        case .optional:
            guard let wrapped = Self.payload(of: payload) else { return nil }
            return routePayload(in: wrapped)
        case .tuple:
            for child in Mirror(reflecting: payload).children {
                if let route = routePayload(in: child.value) {
                    return route
                }
            }
            return nil
        default:
            return payload is any RouteNode ? payload : nil
        }
    }
}

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
        let tab = selectedTab.pathSegment
        guard let chain = paths[selectedTab, default: []].last?.routePath,
            let anchor = chain.firstIndex(of: tab)
        else { return ["app", tab] }

        return ["app"] + chain[anchor...]
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

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "csustplanet", let host = url.host else { return }

        let paths = url.pathComponents.filter { $0 != "/" }

        switch (host, paths.first) {
        case ("features", "electricity"):
            if paths.count > 1,
                let dormId = Int64(paths[1]),
                let pool = DatabaseManager.shared.pool,
                let dorm = try? pool.read({ try DormGRDB.filter(DormGRDB.Columns.id == dormId).fetchOne($0) })
            {
                deepLinkTo(feature: .electricityQuery, path: [.features(.dormList(.detail(dorm)))])
            } else {
                deepLinkTo(feature: .electricityQuery)
            }

        case ("features", "grade-analysis"):
            deepLinkTo(feature: .gradeAnalysis)

        case ("features", "course-schedule"):
            deepLinkTo(feature: .courseSchedule)

        case ("features", "assignments"):
            deepLinkTo(feature: .assignments)

        default:
            break
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
