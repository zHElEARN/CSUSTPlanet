//
//  TodoAssignmentsProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import OSLog
import WidgetKit

struct TodoAssignmentsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoAssignmentsEntry {
        .mockEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoAssignmentsEntry) -> Void) {
        if context.isPreview {
            completion(.mockEntry())
        } else if let cache = MMKVHelper.TodoAssignments.cache {
            completion(.init(date: .now, data: cache.value, lastUpdated: cache.cachedAt))
        } else {
            completion(.init(date: .now, data: nil, lastUpdated: nil))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoAssignmentsEntry>) -> Void) {
        Task {
            Logger.todoAssignmentsWidget.info("开始获取待提交作业数据")

            var finalData = MMKVHelper.TodoAssignments.cache
            if let cache = finalData {
                Logger.todoAssignmentsWidget.info("成功从缓存获取待提交作业数据，共 \(cache.value.count) 门课程")
            } else {
                Logger.todoAssignmentsWidget.info("本地暂无待提交作业缓存数据")
            }

            Logger.todoAssignmentsWidget.info("开始SSO登录流程")
            let ssoHelper = SSOHelper(session: CookieHelper.shared.session)
            let hasValidSession: Bool
            if (try? await ssoHelper.getLoginUser()) == nil {
                Logger.todoAssignmentsWidget.info("未找到有效Cookie，尝试使用账号密码登录")
                if let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword {
                    hasValidSession = (try? await ssoHelper.login(username: username, password: password)) != nil
                    if hasValidSession {
                        Logger.todoAssignmentsWidget.info("账号密码登录SSO成功")
                    } else {
                        Logger.todoAssignmentsWidget.warning("账号密码登录SSO失败")
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
                        let cache = Cached(cachedAt: .now, value: groups)
                        MMKVHelper.TodoAssignments.cache = cache
                        finalData = cache
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

            let entry = TodoAssignmentsEntry(
                date: .now,
                data: finalData?.value,
                lastUpdated: finalData?.cachedAt
            )

            Logger.todoAssignmentsWidget.info("待提交作业 timeline 生成完成")
            completion(Timeline(entries: [entry], policy: .never))
        }
    }
}
