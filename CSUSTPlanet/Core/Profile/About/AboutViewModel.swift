//
//  AboutViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import Foundation
import SwiftData
import WidgetKit

@MainActor
@Observable
final class AboutViewModel {
    // MARK: - Published Properties

    var aboutMarkdown: String?

    // MARK: - Computed Properties

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知版本"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建"
    }

    var environment: String {
        EnvironmentUtil.environment.rawValue
    }

    // MARK: - Initialization

    init() {
        loadAboutMarkdown()
    }

    // MARK: - Methods

    func loadAboutMarkdown() {
        aboutMarkdown = AssetUtil.loadMarkdownFile(named: "About")
    }
}
