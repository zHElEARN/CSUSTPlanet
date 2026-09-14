//
//  ActivitySchedulingStrategy.swift
//  CSUSTPlanet
//
//  Created by 韦亦航 on 2026/9/14.
//

#if os(iOS)

import ActivityKit
import Foundation
import OSLog

/// 课程实时活动的排期策略
///
/// - iOS 26 起系统支持按指定时间预约启动实时活动，可以由系统托管触发与提醒；
/// - 更早的系统只能在 App 位于前台时即时启动实时活动。
///
/// 两条路径都只把「到点启动」交给系统：系统没有按时间结束实时活动的 API，因此「已下课」相位
/// 与 `dismissDate` 清理只能由 App 补正（前台对账，或用户开启「课程实时活动」后台任务后的后台对账，
/// 见 `CourseActivityReconciler`）。
protocol ActivitySchedulingStrategy {
    /// 根据最新的排期计划对齐系统内的实时活动
    /// - Parameters:
    ///   - plans: 排期计划（按触发时间正序）
    ///   - now: 本次对齐的时间基准
    func reconcile(plans: [CourseActivityPlan], now: Date) async
}

/// iOS 26 及之后的排期策略
///
/// 使用 `Activity.request(_:content:pushType:style:alertConfiguration:start:)` 把触发时间最近的
/// 课程预约给系统：即使 App 被终止或设备脱网，系统仍会在上课前 20 分钟启动活动并弹出提醒。
///
/// 系统对同时在跑的实时活动（含尚未触发的预约）有数量上限，因此每次只预约
/// `CourseLiveActivityPlanner.scheduledActivityLimit` 节课（扣减应用内已经进行中的活动，含改课表后
/// 遗留的旧活动），其余课程由 App 下次进入前台时补齐；
/// 该策略只负责「启动」，已下课相位与 `dismissDate` 清理仍由对账补正。
@available(iOS 26.0, *)
struct ScheduledActivityStrategy: ActivitySchedulingStrategy {
    func reconcile(plans: [CourseActivityPlan], now: Date) async {
        await CourseActivityReconciler.reconcileExistingActivities(plans: plans, now: now)

        let ongoingCount = CourseActivityReconciler.ongoingActivities.count
        let quota = CourseLiveActivityPlanner.remainingScheduleQuota(ongoingCount: ongoingCount)
        guard quota > 0 else {
            Logger.activityManager.notice("实时活动并发名额已用尽（进行中 \(ongoingCount) 个），本轮不再预约")
            return
        }

        // 窗口仍按 scheduledActivityLimit 取：窗口内的已有活动要先占住名额，过滤掉之后才按剩余名额裁剪
        let candidates = CourseLiveActivityPlanner.schedulingCandidates(plans: plans, now: now)
            .filter { !CourseActivityReconciler.hasActivity(for: $0) }
            .prefix(quota)

        for (index, plan) in candidates.enumerated() {
            // 循环内复查：同一节课在排期中重复出现时，前一次请求成功后这里会直接跳过
            guard !CourseActivityReconciler.hasActivity(for: plan) else { continue }

            guard await schedule(plan: plan, now: now) else {
                Logger.activityManager.notice("已达系统实时活动并发上限，本轮跳过剩余 \(candidates.count - index - 1) 条排期")
                return
            }
        }
    }

    /// 预约一节课的实时活动；若 App 打开时已过提醒时间，则立即启动
    /// - Returns: 是否还能继续预约后续课程；命中系统并发上限时返回 `false`
    private func schedule(plan: CourseActivityPlan, now: Date) async -> Bool {
        // 已下课的课程只需要清理已有的活动，不再新建
        guard plan.endDate > now else { return true }

        guard plan.triggerDate > now else {
            return await startImmediately(plan: plan, now: now)
        }

        do {
            _ = try Activity.request(
                attributes: plan.attributes,
                content: CourseActivityReconciler.upcomingContent(plan: plan),
                pushType: nil,
                style: .standard,
                alertConfiguration: alertConfiguration(for: plan),
                start: plan.triggerDate
            )
            Logger.activityManager.info("已预约实时活动：\(plan.courseName)")
            return true
        } catch {
            return handleRequestError(error, action: "预约实时活动", courseName: plan.courseName)
        }
    }

    /// App 打开时课程已经进入提醒窗口或正在上课，立即启动活动并让相位与当前时间一致
    /// - Returns: 是否还能继续预约后续课程；命中系统并发上限时返回 `false`
    private func startImmediately(plan: CourseActivityPlan, now: Date) async -> Bool {
        let content =
            now >= plan.startDate
            ? CourseActivityReconciler.inClassContent(plan: plan, now: now)
            : CourseActivityReconciler.upcomingContent(plan: plan)

        do {
            _ = try Activity.request(
                attributes: plan.attributes,
                content: content,
                pushType: nil,
                style: .standard
            )
            Logger.activityManager.info("已立即启动实时活动：\(plan.courseName)")
            return true
        } catch {
            return handleRequestError(error, action: "启动实时活动", courseName: plan.courseName)
        }
    }

    /// 请求失败的处理：命中系统并发上限时交给调用方结束本轮，其余错误记录后继续尝试后续课程
    /// - Returns: 是否可以继续预约后续课程
    private func handleRequestError(_ error: Error, action: String, courseName: String) -> Bool {
        guard !Self.isActivityLimitError(error) else { return false }

        Logger.activityManager.error("\(action)失败：\(courseName) - \(error.localizedDescription)")
        return true
    }

    /// 判断错误是否表示已达系统实时活动的并发上限
    ///
    /// `Activity.request` 的错误既可能直接抛出 `ActivityAuthorizationError`，也可能桥接成同一
    /// error domain 的 `NSError`，两种形态都需要识别。
    static func isActivityLimitError(_ error: Error) -> Bool {
        if let authorizationError = error as? ActivityAuthorizationError {
            switch authorizationError {
            case .globalMaximumExceeded, .targetMaximumExceeded:
                return true
            default:
                return false
            }
        }

        let limitErrorCodes = [
            ActivityAuthorizationError.globalMaximumExceeded.errorCode,
            ActivityAuthorizationError.targetMaximumExceeded.errorCode,
        ]
        let nsError = error as NSError
        return nsError.domain == ActivityAuthorizationError.errorDomain && limitErrorCodes.contains(nsError.code)
    }

    private func alertConfiguration(for plan: CourseActivityPlan) -> AlertConfiguration {
        AlertConfiguration(
            title: LocalizedStringResource(stringLiteral: plan.alertTitle),
            body: LocalizedStringResource(stringLiteral: plan.alertBody),
            sound: .default
        )
    }
}

/// iOS 26 之前的回退策略
///
/// 仅在 App 位于前台、且当前时间命中某节课的提醒窗口时启动实时活动；其后的「课中」相位依赖
/// `staleDate`，「已下课」相位与 `dismissDate` 清理仍由对账补正，与 iOS 26 路径一致。
struct ForegroundActivityStrategy: ActivitySchedulingStrategy {
    func reconcile(plans: [CourseActivityPlan], now: Date) async {
        await CourseActivityReconciler.reconcileExistingActivities(plans: plans, now: now)

        guard let currentPlan = plans.first(where: { now >= $0.triggerDate && now < $0.endDate }) else {
            Logger.activityManager.info("当前没有需要展示的课程")
            return
        }
        guard !CourseActivityReconciler.hasActivity(for: currentPlan) else { return }

        let content =
            now >= currentPlan.startDate
            ? CourseActivityReconciler.inClassContent(plan: currentPlan, now: now)
            : CourseActivityReconciler.upcomingContent(plan: currentPlan)

        do {
            _ = try Activity.request(attributes: currentPlan.attributes, content: content)
            Logger.activityManager.info("已启动实时活动：\(currentPlan.courseName)")
        } catch {
            Logger.activityManager.error("启动实时活动失败：\(currentPlan.courseName) - \(error.localizedDescription)")
        }
    }
}

/// 两个策略共用的活动对齐逻辑
///
/// 对账始终以 `makePlans` 的完整排期为依据，而不是按预约名额裁剪后的候选列表，因此没进入本轮
/// 预约名额的课程不会被误清理。
enum CourseActivityReconciler {
    /// 清理已不在排期内的活动，并补正仍需要的活动
    ///
    /// 活动跌出完整排期时直接结束；仍在排期内的活动按当前时间补正相位：已下课补写为 `.finished`
    /// 并保留到 `dismissDate`，上课时间已到但系统未刷新时补写为 `.inClass`。
    /// - Parameter plans: 完整排期计划（按触发时间正序）
    static func reconcileExistingActivities(plans: [CourseActivityPlan], now: Date) async {
        for activity in Activity<CourseStatusWidgetAttributes>.activities {
            guard let plan = plans.first(where: { $0.matches(activity.attributes) }) else {
                Logger.activityManager.info("实时活动已不在排期内，正在结束：\(activity.attributes.courseName)")
                await activity.end(nil, dismissalPolicy: .immediate)
                continue
            }

            await reconcile(activity: activity, plan: plan, now: now)
        }
    }

    /// 当前进行中的实时活动（含尚未触发的预约）
    ///
    /// `Activity.activities` 在系统移除前仍可能残留 `ended` / `dismissed` 的活动，这些不算进行中：
    /// 用户手动划掉卡片（`dismissed`）后应允许下次进入前台时重新建立，也不应占用并发名额。
    static var ongoingActivities: [Activity<CourseStatusWidgetAttributes>] {
        Activity<CourseStatusWidgetAttributes>.activities.filter { isOngoing($0) }
    }

    /// 判断活动是否处于进行中状态
    static func isOngoing(_ activity: Activity<CourseStatusWidgetAttributes>) -> Bool {
        switch activity.activityState {
        case .pending, .active, .stale:
            return true
        case .ended, .dismissed:
            return false
        default:
            return false
        }
    }

    /// 是否已存在对应排期的进行中实时活动（含尚未触发的预约）
    static func hasActivity(for plan: CourseActivityPlan) -> Bool {
        ongoingActivities.contains { plan.matches($0.attributes) }
    }

    /// 上课前的内容：等待 `staleDate`（上课时间）由系统切换到课中相位
    static func upcomingContent(plan: CourseActivityPlan) -> ActivityContent<CourseStatusWidgetAttributes.ContentState> {
        ActivityContent(
            state: CourseStatusWidgetAttributes.ContentState(phase: .upcoming),
            staleDate: plan.staleDate
        )
    }

    /// 上课中的内容
    ///
    /// 若 App 打开时已经在上课，则把 `staleDate` 设为当前时间，让活动立即进入课中相位。
    static func inClassContent(plan: CourseActivityPlan, now: Date) -> ActivityContent<CourseStatusWidgetAttributes.ContentState> {
        ActivityContent(
            state: CourseStatusWidgetAttributes.ContentState(phase: .inClass),
            staleDate: max(plan.staleDate, now)
        )
    }

    /// 已下课的内容：先由 App 把相位补写为「已下课」，再按 `dismissDate` 交给系统移除
    ///
    /// 该补写只能由 App 触发，系统不会按时间自动切换相位或结束活动。
    static func finishedContent(plan: CourseActivityPlan) -> ActivityContent<CourseStatusWidgetAttributes.ContentState> {
        ActivityContent(
            state: CourseStatusWidgetAttributes.ContentState(phase: .finished),
            staleDate: plan.endDate
        )
    }

    private static func reconcile(activity: Activity<CourseStatusWidgetAttributes>, plan: CourseActivityPlan, now: Date) async {
        // 只处理系统已经启动的活动：尚未触发的预约（pending）由系统按 start 时间启动，
        // 已 ended/dismissed 的活动由系统按 dismissalPolicy 移除，两者都不需要 App 介入
        guard activity.activityState == .active || activity.activityState == .stale else { return }

        if now >= plan.dismissDate {
            Logger.activityManager.info("课程已到清理时间，正在结束实时活动：\(plan.courseName)")
            await activity.end(nil, dismissalPolicy: .immediate)
            return
        }

        if now >= plan.endDate {
            // 系统没有按时间结束活动或切换相位的 API，只能由 App 补写「已下课」，
            // 再把移除时间交给 dismissalPolicy，避免卡片停在“距离下课还有 00:00”
            Logger.activityManager.info("课程已下课，正在补正实时活动：\(plan.courseName)")
            await activity.end(finishedContent(plan: plan), dismissalPolicy: .after(plan.dismissDate))
            return
        }

        guard now >= plan.startDate, activity.content.state.phase == .upcoming else { return }

        // 兜底：系统未在 staleDate 重新渲染时，由 App 把相位补正为课中
        Logger.activityManager.info("课程已开始上课，正在补正实时活动相位：\(plan.courseName)")
        await activity.update(inClassContent(plan: plan, now: now))
    }
}

#endif
