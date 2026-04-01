//
//  Constants.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import Foundation

enum Constants {
    // 基本ID信息
    static let appGroupID = AssetUtil.bundleInfo(forKey: "ConfigAppGroupID")
    static let iCloudID = AssetUtil.bundleInfo(forKey: "ConfigCloudContainerID")
    static let keychainGroup = AssetUtil.bundleInfo(forKey: "ConfigKeychainGroup")
    static let appBundleID = AssetUtil.bundleInfo(forKey: "ConfigAppBundleID")
    static let widgetBundleID = AssetUtil.bundleInfo(forKey: "ConfigWidgetBundleID")

    /// App Group容器URL
    static let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!

    private static let fileManager = FileManager.default

    /// MMKV存储路径
    static let mmkvDirectoryURL: URL = {
        let mmkvDir = sharedContainerURL.appendingPathComponent("mmkv")
        if !fileManager.fileExists(atPath: mmkvDir.path) {
            try? fileManager.createDirectory(at: mmkvDir, withIntermediateDirectories: true)
        }
        return mmkvDir
    }()
    /// MMKV示例ID
    static var mmkvID: String {
        switch EnvironmentUtil.environment {
        case .debug: return "debug"
        case .testFlight: return "testFlight"
        case .appStore: return "appStore"
        }
    }

    /// GRDB数据库路径
    static let grdbDirectoryURL: URL = {
        let grdbDir = sharedContainerURL.appendingPathComponent("grdb")
        if !fileManager.fileExists(atPath: grdbDir.path) {
            try? fileManager.createDirectory(at: grdbDir, withIntermediateDirectories: true)
        }
        return grdbDir
    }()
    /// GRDB数据库文件URL
    static var grdbDatabaseURL: URL {
        let name: String
        switch EnvironmentUtil.environment {
        case .debug: name = "debug"
        case .testFlight: name = "testFlight"
        case .appStore: name = "appStore"
        }
        return grdbDirectoryURL.appendingPathComponent("\(name).sqlite")
    }

    // 后端API地址
    private static let apiHostProd = AssetUtil.bundleInfo(forKey: "ConfigApiHostProd")
    private static let apiHostDev = AssetUtil.bundleInfo(forKey: "ConfigApiHostDev")

    /// 根据环境返回对应的后端地址
    static var backendHost: String {
        switch EnvironmentUtil.environment {
        case .appStore, .testFlight:
            return apiHostProd
        case .debug:
            return apiHostDev
        }
    }

    static let matomoURL = AssetUtil.bundleInfo(forKey: "ConfigMatomoURL")
    private static let matomoSiteIDDev = AssetUtil.bundleInfo(forKey: "ConfigMatomoSiteIDDev")
    private static let matomoSiteIDProd = AssetUtil.bundleInfo(forKey: "ConfigMatomoSiteIDProd")
    static let matomoUserIDSalt = AssetUtil.bundleInfo(forKey: "ConfigMatomoUserIDSalt")
    static let matomoDimensionIDAppFullVersion = AssetUtil.bundleInfo(forKey: "ConfigMatomoDimensionIDAppFullVersion")

    static var matomoSiteID: String {
        switch EnvironmentUtil.environment {
        case .appStore, .testFlight:
            return matomoSiteIDProd
        case .debug:
            return matomoSiteIDDev
        }
    }

    static let backgroundID = AssetUtil.bundleInfo(forKey: "ConfigBackgroundID")

}
