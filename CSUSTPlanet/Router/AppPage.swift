//
//  AppPage.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

import Foundation
import SwiftUI

struct AppPage<Params: RouteParams> {
    var path: String { registration.path }
    let registration: AppRoutes.Registration

    init<Destination: View>(
        _ path: String,
        tab: AppTabItem,
        @ViewBuilder destination: @escaping @MainActor (Params) -> Destination
    ) {
        registration = AppRoutes.Registration(
            path: path,
            tab: tab,
            destination: { entry in
                guard let params = entry.params(as: Params.self) else { return AnyView(EmptyView()) }
                return AnyView(destination(params))
            },
            decode: { items in
                guard let params = Params.decodeDeepLinkQuery(items) else { return nil }
                return RouteEntry(path: path, params: params)
            }
        )
    }

    func entry(_ params: Params) -> RouteEntry {
        RouteEntry(path: path, params: params)
    }

    func deepLink(_ params: Params) -> URL? {
        guard let items = params.deepLinkQueryItems() else { return nil }

        var components = URLComponents()
        components.scheme = AppRoutes.urlScheme
        components.host = AppRoutes.urlHost
        components.path = path
        components.queryItems = items.isEmpty ? nil : items
        return components.url
    }
}

extension AppPage where Params == NoParams {
    init<Destination: View>(_ path: String, tab: AppTabItem, @ViewBuilder destination: @escaping @MainActor () -> Destination) {
        self.init(path, tab: tab) { _ in
            destination()
        }
    }

    func entry() -> RouteEntry { entry(NoParams()) }

    func deepLink() -> URL? { deepLink(NoParams()) }
}
