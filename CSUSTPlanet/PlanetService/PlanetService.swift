//
//  PlanetService.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/24.
//

import Foundation

enum PlanetService {
    static let auth = Auth()
    static let task = Task()

    static var authToken: String? {
        get { MMKVHelper.PlanetService.authToken }
        set { MMKVHelper.PlanetService.authToken = newValue }
    }
}
