//
//  AnnouncementOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import Foundation
import Observation

@MainActor
@Observable
final class AnnouncementOverviewViewModel {
    var title: String = "App公告"
    var subtitle: String = "查看最新 App 公告"
    var linkText: String = "进入公告列表"
}
