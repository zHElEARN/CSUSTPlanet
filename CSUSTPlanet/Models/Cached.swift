//
//  Cached.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/11.
//

import Foundation

struct Cached<T: Codable>: Codable {
    let cachedAt: Date
    let value: T
}
