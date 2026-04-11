//
//  RefreshGradeAnalysisTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/22.
//

import AppIntents
import CSUSTKit
import OSLog
import WidgetKit

struct RefreshGradeAnalysisTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新成绩分析时间线"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        Logger.gradeAnalysisWidget.info("用户触发手动刷新，Intent 开始联网获取数据")

        let ssoHelper = SSOHelper(session: CookieHelper.shared.session)

        // 先尝试使用保存的cookie登录统一认证
        let hasValidSSOSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            Logger.gradeAnalysisWidget.info("未找到有效Cookie，尝试使用账号密码登录")
            // 保存的cookie无效，尝试账号密码登录
            if let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword {
                hasValidSSOSession = (try? await ssoHelper.login(username: username, password: password)) != nil
            } else {
                hasValidSSOSession = false
            }
        } else {
            Logger.gradeAnalysisWidget.info("找到有效Cookie，无需使用账号密码登录")
            hasValidSSOSession = true
        }

        // 登录教务系统并获取数据
        if hasValidSSOSession, let eduHelper = try? EduHelper(session: await ssoHelper.loginToEducation()) {
            Logger.gradeAnalysisWidget.info("EduHelper初始化成功")

            if let courseGrades = try? await eduHelper.courseService.getCourseGrades(), !courseGrades.isEmpty {
                Logger.gradeAnalysisWidget.info("成功从EduHelper获取成绩")

                MMKVHelper.CourseGrades.cache = Cached<[EduHelper.CourseGrade]>(cachedAt: .now, value: courseGrades)
                Logger.gradeAnalysisWidget.info("已将最新成绩数据写入缓存")
            } else {
                Logger.gradeAnalysisWidget.info("获取到的成绩数据为空或获取失败")
            }
        } else {
            Logger.gradeAnalysisWidget.error("SSO登录失败，无法初始化EduHelper")
        }

        return .result()
    }
}
