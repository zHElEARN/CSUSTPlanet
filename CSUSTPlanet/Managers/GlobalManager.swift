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
        appearance = MMKVHelper.shared.appearance
        isUserAgreementAccepted = MMKVHelper.shared.isUserAgreementAccepted
        isLiveActivityEnabled = MMKVHelper.shared.isLiveActivityEnabled
        isWebVPNModeEnabled = MMKVHelper.shared.isWebVPNModeEnabled
        isNotificationEnabled = MMKVHelper.shared.isNotificationEnabled
        isBackgroundTaskEnabled = MMKVHelper.shared.isBackgroundTaskEnabled

        TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)
        TrackHelper.shared.event(category: "LiveActivity", action: "Status", name: isLiveActivityEnabled ? "Enabled" : "Disabled")
        TrackHelper.shared.event(category: "WebVPN", action: "Status", name: isWebVPNModeEnabled ? "Enabled" : "Disabled")
        TrackHelper.shared.event(category: "BackgroundTask", action: "Status", name: isBackgroundTaskEnabled ? "Enabled" : "Disabled")
    }

    var selectedTab: TabItem? = .overview
    var appearance: String {
        didSet { MMKVHelper.shared.appearance = appearance }
    }
    var isUserAgreementAccepted: Bool {
        didSet {
            MMKVHelper.shared.isUserAgreementAccepted = isUserAgreementAccepted
            TrackHelper.shared.updateIsOptedOut(!isUserAgreementAccepted)
        }
    }
    var isUserAgreementShowing: Binding<Bool> {
        Binding(get: { !self.isUserAgreementAccepted }, set: { self.isUserAgreementAccepted = !$0 })
    }
    var isLiveActivityEnabled: Bool {
        didSet {
            MMKVHelper.shared.isLiveActivityEnabled = isLiveActivityEnabled
            TrackHelper.shared.event(category: "LiveActivity", action: "Status", name: isLiveActivityEnabled ? "Enabled" : "Disabled")
        }
    }
    var isWebVPNModeEnabled: Bool {
        didSet {
            MMKVHelper.shared.isWebVPNModeEnabled = isWebVPNModeEnabled
            TrackHelper.shared.event(category: "WebVPN", action: "Status", name: isWebVPNModeEnabled ? "Enabled" : "Disabled")
        }
    }
    var isNotificationEnabled: Bool {
        didSet { MMKVHelper.shared.isNotificationEnabled = isNotificationEnabled }
    }
    var isBackgroundTaskEnabled: Bool {
        didSet {
            MMKVHelper.shared.isBackgroundTaskEnabled = isBackgroundTaskEnabled
            TrackHelper.shared.event(category: "BackgroundTask", action: "Status", name: isBackgroundTaskEnabled ? "Enabled" : "Disabled")
        }
    }

    var isFromElectricityWidget: Bool = false
    var isFromGradeAnalysisWidget: Bool = false
    var isFromCourseScheduleWidget: Bool = false
    var isFromUrgentCoursesWidget: Bool = false

    var showWipeRecoveryAlert = (SharedModelUtil.containerLoadState == .recoveredAfterWipe)
    var showFatalErrorAlert = (SharedModelUtil.containerLoadState == .fatalError)
}
