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
        TrackHelper.shared.event(category: "Widget", action: "Refresh", name: "TodoAssignmentsWidget")
        await Self.update()
        return .result()
    }

    static func update() async {
        let ssoHelper = SSOHelper(session: CookieHelper.shared.session)

        let hasValidSession: Bool
        if (try? await ssoHelper.getLoginUser()) == nil {
            if let username = KeychainUtil.ssoUsername,
                let password = KeychainUtil.ssoPassword,
                let loginForm = try? await ssoHelper.getLoginForm()
            {
                hasValidSession = (try? await ssoHelper.login(loginForm: loginForm, username: username, password: password, captcha: nil)) != nil
            } else {
                hasValidSession = false
            }
        } else {
            hasValidSession = true
        }

        if hasValidSession, let moocHelper = try? MoocHelper(session: await ssoHelper.loginToMooc()) {
            if let courses = try? await moocHelper.getCoursesWithPendingAssignments() {
                var groups: [TodoAssignmentsData] = []
                var fetchFailed = false

                for course in courses {
                    guard let assignments = try? await moocHelper.getCourseAssignments(course: course) else {
                        fetchFailed = true
                        break
                    }
                    groups.append(.init(course: course, assignments: assignments))
                }

                if !fetchFailed {
                    MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: groups)
                }
            }
        }
    }
}
