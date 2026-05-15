//
//  Logger+Categories.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/12/16.
//

import Foundation
import OSLog

extension Logger {
    private static var appSubsystem = Constants.appBundleID
    private static var widgetSubsystem = Constants.widgetBundleID

    init(appCategory: String) {
        self.init(subsystem: Self.appSubsystem, category: appCategory)
    }

    init(widgetCategory: String) {
        self.init(subsystem: Self.widgetSubsystem, category: widgetCategory)
    }
}
