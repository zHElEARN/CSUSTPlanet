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
    /// MMK实例ID
    static let mmkvID: String = {
        switch EnvironmentUtil.environment {
        case .debug: return "debug"
        case .testFlight: return "testFlight"
        case .appStore: return "appStore"
        }
    }()
    /// MMKV IPC前缀
    static let mmkvIPCPrefix: String = "\(appBundleID).IPC.MMKV"

    /// GRDB数据库路径
    static let grdbDirectoryURL: URL = {
        let grdbDir = sharedContainerURL.appendingPathComponent("grdb")
        if !fileManager.fileExists(atPath: grdbDir.path) {
            try? fileManager.createDirectory(at: grdbDir, withIntermediateDirectories: true)
        }
        return grdbDir
    }()
    /// GRDB数据库文件URL
    static let grdbDatabaseURL: URL = {
        let name: String
        switch EnvironmentUtil.environment {
        case .debug: name = "debug"
        case .testFlight: name = "testFlight"
        case .appStore: name = "appStore"
        }
        return grdbDirectoryURL.appendingPathComponent("\(name).sqlite")
    }()
    /// GRDB IPC名称
    static let grdbIPCName: String = "\(appBundleID).IPC.GRDB"

    // 后端API地址
    private static let apiHostProd = AssetUtil.bundleInfo(forKey: "ConfigApiHostProd")
    private static let apiHostDev = AssetUtil.bundleInfo(forKey: "ConfigApiHostDev")

    /// 根据环境返回对应的后端地址
    static let backendHost: String = {
        switch EnvironmentUtil.environment {
        case .appStore, .testFlight:
            return apiHostProd
        case .debug:
            return apiHostDev
        }
    }()

    static let matomoURL = AssetUtil.bundleInfo(forKey: "ConfigMatomoURL")
    static let matomoSiteID = AssetUtil.bundleInfo(forKey: "ConfigMatomoSiteID")
    static let matomoDimensionIDAppVersion = AssetUtil.bundleInfo(forKey: "ConfigMatomoDimensionIDAppVersion")
    static let matomoDimensionIDAppEnvironment = AssetUtil.bundleInfo(forKey: "ConfigMatomoDimensionIDAppEnvironment")

    static let backgroundID = AssetUtil.bundleInfo(forKey: "ConfigBackgroundID")
}
