//
//  GlobalManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation
import OSLog
import SwiftUI

#if os(macOS)
import AppKit
#endif

enum TabItem: String {
    case overview
    case features
    case profile

    // 以下部分仅在horizontalSizeClass为.regular的情况下会被使用

    // 教务系统
    case courseSchedule
    case gradeQuery
    case examSchedule
    case gradeAnalysis

    // 网络课程中心
    case courses
    case urgentCourses

    // 校园工具
    case electricityQuery
    case availableClassroom
    case campusMap
    case schoolCalendar
    case electricityRecharge
    case webVPNConverter

    // 大学物理实验
    case physicsExperimentSchedule
    case physicsExperimentGrade

    // 其他考试查询
    case cet
    case mandarin
}

@Observable
@MainActor
final class GlobalManager {
    static let shared = GlobalManager()

    @ObservationIgnored private var isCheckingAppVersion = false
    @ObservationIgnored private var isMigratingDatabase = false

    private init() {
        appearance = MMKVHelper.GlobalManager.appearance
        isUserAgreementAccepted = MMKVHelper.GlobalManager.isUserAgreementAccepted
        isWebVPNModeEnabled = MMKVHelper.GlobalManager.isWebVPNModeEnabled
        isMigratingToGRDB = !MMKVHelper.SwiftData.hasMigratedToGRDB

        #if os(macOS)
        applyMacOSAppearance(appearance)
        #endif

        TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)

        Task { await checkAppVersion() }
    }

    var selectedTab: TabItem? = .overview
    var appearance: String {
        didSet {
            MMKVHelper.GlobalManager.appearance = appearance
            #if os(macOS)
            applyMacOSAppearance(appearance)
            #endif
        }
    }
    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }
    var isUserAgreementAccepted: Bool {
        didSet {
            MMKVHelper.GlobalManager.isUserAgreementAccepted = isUserAgreementAccepted
            TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)
        }
    }
    var isUserAgreementShowing: Binding<Bool> {
        Binding(get: { !self.isUserAgreementAccepted }, set: { self.isUserAgreementAccepted = !$0 })
    }
    var isWebVPNModeEnabled: Bool {
        didSet {
            MMKVHelper.GlobalManager.isWebVPNModeEnabled = isWebVPNModeEnabled
        }
    }

    var hasDatabaseFatalError = DatabaseManager.shared.hasFatalError
    var databaseFatalErrorMessage: String = DatabaseManager.shared.fatalErrorMessage
    var isMigratingToGRDB: Bool

    var latestAppVersion: PlanetConfigService.AppVersion?
    var isAppUpdateSheetPresented: Bool = false
    var isForceUpdateRequired: Bool = false

    var unreadAnnouncementsCount: Int = 0

    var isFromElectricityWidget: Bool = false
    var isFromGradeAnalysisWidget: Bool = false
    var isFromCourseScheduleWidget: Bool = false
    var isFromTodoAssignmentsWidget: Bool = false

    private func checkAppVersion() async {
        guard !isCheckingAppVersion else { return }
        isCheckingAppVersion = true
        defer { isCheckingAppVersion = false }

        guard let currentVersionName = AppVersionHelper.currentVersionName, let currentVersionCode = AppVersionHelper.currentVersionCode else {
            Logger.globalManager.error("启动版本检查失败：无法解析当前版本号")
            return
        }

        do {
            let result = try await PlanetConfigService.checkAppVersion(currentVersionCode: currentVersionCode)

            guard result.hasUpdate else {
                Logger.globalManager.debug("启动版本检查完成：当前已是最新版本 \(currentVersionName, privacy: .public) (\(currentVersionCode))")
                return
            }

            guard let latestVersion = result.latestVersion else {
                Logger.globalManager.error("启动版本检查结果异常：hasUpdate 为 true 但 latestVersion 为空")
                return
            }

            if !result.isForceUpdate, MMKVHelper.GlobalManager.ignoredAppUpdateVersionCode == latestVersion.versionCode {
                Logger.globalManager.info("启动版本检查发现已忽略的版本更新：\(latestVersion.versionName, privacy: .public) (\(latestVersion.versionCode))，本次不再提示")
                return
            }

            self.latestAppVersion = latestVersion
            isForceUpdateRequired = result.isForceUpdate
            isAppUpdateSheetPresented = true

            Logger.globalManager.info("启动版本检查发现新版本：当前 \(currentVersionName, privacy: .public) (\(currentVersionCode))，最新 \(latestVersion.versionName, privacy: .public) (\(latestVersion.versionCode))，强制更新：\(result.isForceUpdate)")
        } catch {
            Logger.globalManager.error("启动版本检查失败：\(error.localizedDescription, privacy: .public)")
        }
    }

    func dismissAppUpdateSheet() {
        guard !isForceUpdateRequired else { return }
        isAppUpdateSheetPresented = false
    }

    func migrateDatabaseIfNeeded() async {
        guard isMigratingToGRDB, !isMigratingDatabase else { return }
        isMigratingDatabase = true
        defer { isMigratingDatabase = false }

        await SwiftDataToGRDBMigrator.migrateIfNeeded()

        withAnimation {
            isMigratingToGRDB = false
        }
    }

    #if os(macOS)
    private func applyMacOSAppearance(_ appearanceName: String) {
        switch appearanceName {
        case "light":
            PlatformApplication.shared.appearance = NSAppearance(named: .aqua)
        case "dark":
            PlatformApplication.shared.appearance = NSAppearance(named: .darkAqua)
        default:
            PlatformApplication.shared.appearance = nil
        }
    }
    #endif

    func ignoreCurrentAppUpdate() {
        guard !isForceUpdateRequired, let latestAppVersion else { return }
        MMKVHelper.GlobalManager.ignoredAppUpdateVersionCode = latestAppVersion.versionCode
        Logger.globalManager.info("用户已忽略版本更新：\(latestAppVersion.versionName, privacy: .public) (\(latestAppVersion.versionCode))")
        dismissAppUpdateSheet()
    }
}

extension MMKVHelper {
    enum GlobalManager {
        @MMKVStorage(key: "GlobalVars.appearance", defaultValue: "system")
        static var appearance: String

        @MMKVStorage(key: "GlobalVars.isUserAgreementAccepted", defaultValue: false)
        static var isUserAgreementAccepted: Bool

        @MMKVStorage(key: "GlobalVars.isWebVPNModeEnabled", defaultValue: false)
        static var isWebVPNModeEnabled: Bool

        @MMKVOptionalStorage(key: "GlobalVars.ignoredAppUpdateVersionCode")
        static var ignoredAppUpdateVersionCode: Int?
    }
}
