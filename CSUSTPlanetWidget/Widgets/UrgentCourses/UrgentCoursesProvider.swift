//
//  UrgentCoursesProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import WidgetKit

struct UrgentCoursesProvider: TimelineProvider {
    func placeholder(in context: Context) -> UrgentCoursesEntry {
        .mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (UrgentCoursesEntry) -> Void) {
        completion(.mockEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UrgentCoursesEntry>) -> Void) {
        Task {
            var finalData: Cached<UrgentCoursesData>? = nil
            if let urgentCourses = MMKVHelper.shared.urgentCoursesCache {
                finalData = urgentCourses
            }

            let ssoHelper = SSOHelper(session: CookieHelper.shared.session)
            let hasValidSession: Bool
            if (try? await ssoHelper.getLoginUser()) == nil {
                if let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword {
                    hasValidSession = (try? await ssoHelper.login(username: username, password: password)) != nil
                } else {
                    hasValidSession = false
                }
            } else {
                hasValidSession = true
            }

            if hasValidSession, let moocHelper = try? MoocHelper(session: await ssoHelper.loginToMooc()) {
                if let urgentCourses = try? await moocHelper.getCourseNamesWithPendingAssignments() {
                    finalData = Cached<UrgentCoursesData>(cachedAt: .now, value: UrgentCoursesData.fromCourses(urgentCourses))
                }
            }

            let entry = UrgentCoursesEntry(
                date: .now,
                data: finalData?.value,
                lastUpdated: finalData?.cachedAt
            )

            completion(Timeline(entries: [entry], policy: .never))
        }
    }
}
