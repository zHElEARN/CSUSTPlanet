//
//  GlobalManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import Foundation
import SwiftUI

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

    private init() {
        appearance = MMKVHelper.GlobalManager.appearance
        isUserAgreementAccepted = MMKVHelper.GlobalManager.isUserAgreementAccepted
        isWebVPNModeEnabled = MMKVHelper.GlobalManager.isWebVPNModeEnabled

        TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)
    }

    var selectedTab: TabItem? = .overview
    var appearance: String {
        didSet { MMKVHelper.GlobalManager.appearance = appearance }
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

    var isFromElectricityWidget: Bool = false
    var isFromGradeAnalysisWidget: Bool = false
    var isFromCourseScheduleWidget: Bool = false
    var isFromUrgentCoursesWidget: Bool = false
}

extension MMKVHelper {
    enum GlobalManager {
        @MMKVStorage(key: "GlobalVars.appearance", defaultValue: "system")
        static var appearance: String

        @MMKVStorage(key: "GlobalVars.isUserAgreementAccepted", defaultValue: false)
        static var isUserAgreementAccepted: Bool

        @MMKVStorage(key: "GlobalVars.isWebVPNModeEnabled", defaultValue: false)
        static var isWebVPNModeEnabled: Bool
    }
}
