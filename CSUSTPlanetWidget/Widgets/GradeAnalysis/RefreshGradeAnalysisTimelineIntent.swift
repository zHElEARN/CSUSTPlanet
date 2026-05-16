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
        await Self.update()
        return .result()
    }

    static func update() async {
        let ssoHelper = SSOHelper(session: CookieHelper.shared.session)

        // 先尝试使用保存的cookie登录统一认证
        let hasValidSSOSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            // 保存的cookie无效，尝试账号密码登录
            if let username = KeychainUtil.ssoUsername,
                let password = KeychainUtil.ssoPassword,
                let loginForm = try? await ssoHelper.getLoginForm()
            {
                hasValidSSOSession = (try? await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)) != nil
            } else {
                hasValidSSOSession = false
            }
        } else {
            hasValidSSOSession = true
        }

        // 登录教务系统并获取数据
        if hasValidSSOSession,
            let eduHelper = try? EduHelper(session: await ssoHelper.loginToEducation()),
            let courseGrades = try? await eduHelper.courseService.getCourseGrades(),
            !courseGrades.isEmpty
        {
            MMKVHelper.CourseGrades.cache = Cached<[EduHelper.CourseGrade]>(cachedAt: .now, value: courseGrades)
        }
    }
}
