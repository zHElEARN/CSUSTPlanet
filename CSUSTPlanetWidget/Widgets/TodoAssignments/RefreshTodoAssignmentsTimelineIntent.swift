//
//  RefreshTodoAssignmentsTimelineIntent.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/3/27.
//

import AppIntents
import CSUSTKit
import OSLog
import WidgetKit

struct RefreshTodoAssignmentsTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新待提交作业时间线"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        Logger.todoAssignmentsWidget.info("用户触发手动刷新，Intent 开始联网获取数据")

        let ssoHelper = SSOHelper(session: CookieHelper.shared.session)

        let hasValidSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            Logger.todoAssignmentsWidget.info("未找到有效Cookie，尝试使用账号密码登录")
            if let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword {
                if let loginForm = try? await ssoHelper.getLoginForm() {
                    hasValidSession = (try? await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)) != nil
                    if hasValidSession {
                        Logger.todoAssignmentsWidget.info("账号密码登录SSO成功")
                    } else {
                        Logger.todoAssignmentsWidget.warning("账号密码登录SSO失败")
                    }
                } else {
                    Logger.todoAssignmentsWidget.warning("获取SSO登录表单失败，无法登录")
                    hasValidSession = false
                }
            } else {
                Logger.todoAssignmentsWidget.warning("未保存SSO账号密码，无法重新登录")
                hasValidSession = false
            }
        } else {
            Logger.todoAssignmentsWidget.info("找到有效Cookie，无需使用账号密码登录")
            hasValidSession = true
        }

        if hasValidSession, let moocHelper = try? MoocHelper(session: await ssoHelper.loginToMooc()) {
            Logger.todoAssignmentsWidget.info("MoocHelper初始化成功")

            if let courses = try? await moocHelper.getCoursesWithPendingAssignments() {
                Logger.todoAssignmentsWidget.info("成功获取有待提交作业的课程，共 \(courses.count) 门")
                var groups: [TodoAssignmentsData] = []
                var fetchFailed = false

                for course in courses {
                    guard let assignments = try? await moocHelper.getCourseAssignments(course: course) else {
                        Logger.todoAssignmentsWidget.warning("获取课程 \(course.name) 的作业失败，保留旧缓存")
                        fetchFailed = true
                        break
                    }

                    Logger.todoAssignmentsWidget.info("成功获取课程 \(course.name) 的作业，共 \(assignments.count) 个")
                    groups.append(.init(course: course, assignments: assignments))
                }

                if !fetchFailed {
                    MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: groups)
                    Logger.todoAssignmentsWidget.info("成功创建并写入待提交作业缓存，共 \(groups.count) 门课程")
                }
            } else {
                Logger.todoAssignmentsWidget.warning("获取待提交作业课程列表失败，保留旧缓存")
            }
        } else if hasValidSession {
            Logger.todoAssignmentsWidget.warning("MoocHelper初始化失败，保留旧缓存")
        } else {
            Logger.todoAssignmentsWidget.warning("SSO登录失败，跳过网络获取，保留旧缓存")
        }

        return .result()
    }
}
