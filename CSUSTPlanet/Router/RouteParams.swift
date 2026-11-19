//
//  RouteParams.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

import Foundation

protocol RouteParams: Hashable, Codable {}

extension RouteParams {
    func deepLinkQueryItems() -> [URLQueryItem]? {
        if self is NoParams { return [] }
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return [URLQueryItem(name: "params", value: String(decoding: data, as: UTF8.self))]
    }

    static func decodeDeepLinkQuery(_ items: [URLQueryItem]) -> Self? {
        if let noParams = NoParams() as? Self {
            return items.isEmpty ? noParams : nil
        }
        guard items.count == 1, let item = items.first, item.name == "params", let json = item.value else { return nil }
        return try? JSONDecoder().decode(Self.self, from: Data(json.utf8))
    }
}

struct NoParams: RouteParams {}
