//
//  AppRoutes.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

import Foundation
import SwiftUI

enum AppRoutes {
    struct Registration {
        let path: String
        let tab: AppTabItem
        let destination: @MainActor (RouteEntry) -> AnyView
        let decode: ([URLQueryItem]) -> RouteEntry?
    }

    static let urlScheme = "csustplanet"
    static let urlHost = "app"

    private static let pagesByPath = Dictionary(uniqueKeysWithValues: registrations.map { ($0.path, $0) })

    @MainActor
    static func destination(for entry: RouteEntry) -> AnyView {
        pagesByPath[entry.path]?.destination(entry) ?? AnyView(EmptyView())
    }

    static func tab(for entry: RouteEntry) -> AppTabItem? {
        pagesByPath[entry.path]?.tab
    }

    static func entry(for url: URL) -> RouteEntry? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme?.lowercased() == urlScheme, components.host?.lowercased() == urlHost,
            components.user == nil, components.password == nil, components.port == nil, components.fragment == nil
        else { return nil }

        return pagesByPath[components.percentEncodedPath]?.decode(components.queryItems ?? [])
    }
}
