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
                deepLinkTo(feature: .electricityQuery, path: [.features(.campusTool(.dormList(.detail(.main(dorm)))))])
            } else {
                deepLinkTo(feature: .electricityQuery)
            }

        case ("features", "grade-analysis"):
            deepLinkTo(feature: .gradeAnalysis)

        case ("features", "course-schedule"):
            deepLinkTo(feature: .courseSchedule)

        case ("features", "todo-assignments"):
            deepLinkTo(feature: .urgentCourses)

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
