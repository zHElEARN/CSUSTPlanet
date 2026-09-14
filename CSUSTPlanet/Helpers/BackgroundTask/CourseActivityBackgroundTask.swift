//
//  CourseActivityBackgroundTask.swift
//  CSUSTPlanet
//
//  Created by 韦亦航 on 2026/9/15.
//

#if os(iOS)

import ActivityKit
import Foundation
import OSLog

/// 后台补正课程实时活动的「已下课」相位与清理
///
/// 系统没有按时间结束实时活动的 API，下课后也不会再次渲染卡片，因此「已下课」相位与 `dismissDate`
/// 清理只能由 App 补正（见 `CourseActivityReconciler`）。该 provider 复用前台同一条对账逻辑，但只做
/// `Activity.update` / `Activity.end`：后台调用 `Activity.request` 会抛
/// `ActivityAuthorizationError.visibility`，因此这里不新建任何预约，新的排期仍由 App 进入前台时补齐。
struct CourseActivityBackgroundTask: BackgroundTaskProvider {
    let identifier: String = "courseActivity"

    let title: String = "课程实时活动"
    let description: String = "在后台结束已经下课的实时活动，让锁屏卡片显示「已下课」并按计划消失"

    func perform() async -> Bool {
        let isEnabled = await MainActor.run { ActivityManager.shared.isEnabled }
        guard isEnabled else {
            Logger.courseActivityBackgroundTask.debug("实时活动已禁用，跳过后台对账")
            return true
        }

        guard let data = MMKVHelper.CourseSchedule.activeCourseSchedule?.value.data else {
            Logger.courseActivityBackgroundTask.debug("未找到课表数据，跳过后台对账")
            return true
        }

        let activities = CourseActivityReconciler.ongoingActivities
        guard !activities.isEmpty else {
            Logger.courseActivityBackgroundTask.debug("没有进行中的实时活动，跳过后台对账")
            return true
        }

        let now = Date()
        let plans = CourseLiveActivityPlanner.makePlans(
            semesterStartDate: data.semesterStartDate,
            now: now,
            courses: data.courses,
            weekCount: data.weekCount
        )

        do {
            try Task.checkCancellation()
            await CourseActivityReconciler.reconcileExistingActivities(plans: plans, now: now)
        } catch {
            Logger.courseActivityBackgroundTask.debug("后台对账因任务超时被取消")
            return false
        }

        Logger.courseActivityBackgroundTask.debug("后台对账完成，共 \(plans.count) 条排期、\(activities.count) 个进行中的活动")
        return true
    }
}

extension Logger {
    static let courseActivityBackgroundTask = Logger(appCategory: "CourseActivityBackgroundTask")
}

#endif
