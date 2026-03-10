//
//  GradeAnalysisProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import Foundation
import OSLog
import WidgetKit

struct GradeAnalysisProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> GradeAnalysisEntry {
        .mockEntry()
    }

    func snapshot(for configuration: GradeAnalysisAppIntent, in context: Context) async -> GradeAnalysisEntry {
        if context.isPreview {
            return .mockEntry(configuration: configuration)
        } else if let gradeAnalysis = MMKVHelper.shared.courseGradesCache {
            return .init(date: .now, configuration: configuration, data: GradeAnalysisData.fromCourseGrades(gradeAnalysis.value), lastUpdated: gradeAnalysis.cachedAt)
        } else {
            return .mockEntry(configuration: configuration)
        }
    }

    func timeline(for configuration: GradeAnalysisAppIntent, in context: Context) async -> Timeline<GradeAnalysisEntry> {
        Logger.gradeAnalysisWidget.info("开始获取成绩分析数据")

        var finalData: Cached<[EduHelper.CourseGrade]>? = nil

        // 先从缓存中获取成绩分析
        if let gradeAnalysis = MMKVHelper.shared.courseGradesCache {
            Logger.gradeAnalysisWidget.info("成功从缓存获取成绩分析数据")
            finalData = gradeAnalysis
        }

        // 再尝试联网获取数据
        Logger.gradeAnalysisWidget.info("开始SSO登录流程")
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

        if hasValidSSOSession, let eduHelper = try? EduHelper(session: await ssoHelper.loginToEducation()) {
            Logger.gradeAnalysisWidget.info("EduHelper初始化成功")
            // 教务系统登录成功
            if let courseGrades = try? await eduHelper.courseService.getCourseGrades(), !courseGrades.isEmpty {
                Logger.gradeAnalysisWidget.info("成功从EduHelper获取成绩")
                // 成绩获取成功
                finalData = Cached<[EduHelper.CourseGrade]>(cachedAt: .now, value: courseGrades)
                Logger.gradeAnalysisWidget.info("成功创建最终成绩分析数据")
            }
        }

        let entry = GradeAnalysisEntry(
            date: .now,
            configuration: configuration,
            data: GradeAnalysisData.fromCourseGrades(finalData?.value ?? []),
            lastUpdated: finalData?.cachedAt
        )

        return Timeline(entries: [entry], policy: .never)
    }
}
