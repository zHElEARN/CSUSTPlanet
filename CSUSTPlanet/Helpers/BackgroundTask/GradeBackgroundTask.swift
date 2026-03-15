//
//  GradeBackgroundTask.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

#if os(iOS)

import BackgroundTasks
import CSUSTKit
import Foundation
import OSLog
import UserNotifications

struct GradeBackgroundTask: BackgroundTaskProvider {
    let identifier: String = "grade"

    let title: String = "查询成绩"
    let description: String = "在后台查询当前教务系统的所有成绩，并在成绩有更新时发送通知"

    func perform() async -> Bool {
        Logger.gradeBackgroundTask.debug("开始后台获取成绩")
        do {
            let mode: ConnectionMode = MMKVHelper.shared.isWebVPNModeEnabled ? .webVpn : .direct
            let session = CookieHelper.shared.session
            let ssoHelper = SSOHelper(mode: mode, session: session)
            let eduHelper = EduHelper(mode: mode, session: session)

            if await !ssoHelper.isLoggedIn() {
                Logger.gradeBackgroundTask.debug("统一身份认证未登录，尝试重新登录")
                guard let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword else {
                    Logger.gradeBackgroundTask.warning("获取成绩失败: 统一身份认证登录失败，密码未保存")
                    return false
                }
                try await ssoHelper.login(username: username, password: password)
                Logger.gradeBackgroundTask.debug("统一身份认证登录成功")
                _ = try await ssoHelper.loginToEducation()
                Logger.gradeBackgroundTask.debug("教务系统登录成功")
            } else {
                Logger.gradeBackgroundTask.debug("统一身份认证已登录，验证教务系统登录")
                if await !eduHelper.isLoggedIn() {
                    _ = try await ssoHelper.loginToEducation()
                    Logger.gradeBackgroundTask.debug("教务系统登录成功")
                }
            }
            CookieHelper.shared.save()

            // 获取上次缓存的成绩
            let lastCourseGrades = MMKVHelper.shared.courseGradesCache?.value ?? []

            // 重试机制：最多尝试 3 次
            var nowCourseGrades: [EduHelper.CourseGrade] = []
            for i in 1...3 {
                try Task.checkCancellation()
                do {
                    nowCourseGrades = try await eduHelper.courseService.getCourseGrades()
                    if !nowCourseGrades.isEmpty {
                        Logger.gradeBackgroundTask.debug("第 \(i) 次尝试获取成绩成功: \(nowCourseGrades.count)门课程")
                        break
                    }
                    Logger.gradeBackgroundTask.warning("第 \(i) 次尝试获取成绩返回为空数组")
                } catch {
                    Logger.gradeBackgroundTask.warning("第 \(i) 次获取成绩发生网络或解析错误: \(error.localizedDescription)")
                }

                if i < 3 {
                    try await Task.sleep(for: .seconds(2))
                }
            }

            // 最终结果校验与对比
            if nowCourseGrades.isEmpty {
                if lastCourseGrades.isEmpty {
                    // 如果原本就没成绩（比如新生），那么返回空是正常的
                    Logger.gradeBackgroundTask.debug("未获取到成绩，且本地无缓存，判定为当前暂无成绩")
                    return true
                } else {
                    // 如果原本有成绩但现在返回空，判定为教务系统抽风或网络彻底失败
                    Logger.gradeBackgroundTask.error("获取成绩失败: 多次尝试后仍返回空数组或请求失败")
                    return false
                }
            }

            // 走到这里说明 nowCourseGrades 肯定不为空
            if lastCourseGrades != nowCourseGrades {
                Logger.gradeBackgroundTask.debug("成绩发生变化，准备更新缓存并处理通知")
                MMKVHelper.shared.courseGradesCache = .init(cachedAt: .now, value: nowCourseGrades)

                let content = UNMutableNotificationContent()
                content.title = "成绩更新提醒"
                content.body = "检测到教务系统成绩有变动，点击查看详情。"
                content.sound = .default
                content.badge = 0

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

                do {
                    try await UNUserNotificationCenter.current().add(request)
                    Logger.gradeBackgroundTask.debug("推送设置成功")
                } catch {
                    Logger.gradeBackgroundTask.error("推送调度失败: \(error.localizedDescription)")
                }
            } else {
                Logger.gradeBackgroundTask.debug("成绩未发生变化")
            }

            return true
        } catch {
            if error is CancellationError {
                Logger.gradeBackgroundTask.debug("后台任务因超时被系统取消，跳过常规错误处理")
                return false
            }
            Logger.gradeBackgroundTask.error("获取成绩失败: \(error.localizedDescription)")
            return false
        }
    }
}
#endif
