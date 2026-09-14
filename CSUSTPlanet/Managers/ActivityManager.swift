//
//  ActivityManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

#if os(iOS)

import ActivityKit
import Combine
import Foundation
import OSLog

/// 课程实时活动的编排
///
/// iOS 26 起把触发时间最近的课程预约给系统托管（上课前 20 分钟自动启动并提醒），预约数量受
/// `CourseLiveActivityPlanner.scheduledActivityLimit` 限制，其余课程在 App 每次进入前台时补齐；
/// 更早的系统只保留“App 位于前台时启动当前课程”的回退逻辑。两条路径的相位切换与清理规则一致。
///
/// 系统只负责按时间启动活动：「已下课」相位与 `dismissDate` 清理没有对应的系统 API，均由 App
/// 补正（见 `CourseActivityReconciler`）：进入前台时的对账，以及用户开启「课程实时活动」后台任务后
/// 的后台对账。
@MainActor
@Observable
final class ActivityManager {
    static let shared = ActivityManager()

    private var cancellables = Set<AnyCancellable>()

    /// 是否正在对齐系统内的实时活动，避免并发请求造成重复预约
    private var isReconciling = false
    /// 对齐过程中是否又收到了新的对齐请求
    private var needsReconcile = false

    var isEnabled: Bool {
        didSet {
            MMKVHelper.ActivityManager.isEnabled = isEnabled
            autoUpdateActivity()
        }
    }

    private init() {
        isEnabled = MMKVHelper.ActivityManager.isEnabled
        startObservingLifecycle()

        Logger.activityManager.info("ActivityManager 已初始化")
        autoUpdateActivity()
    }

    private func startObservingLifecycle() {
        LifecycleManager.shared.events
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .didBecomeActive, .didBecomeInactive:
                    self.autoUpdateActivity()
                case .didEnterBackground:
                    break
                }
            }
            .store(in: &cancellables)
    }

    /// 按最新课表对齐系统内的课程实时活动
    ///
    /// 调用时机：App 进入前台/退到后台、课表数据变化、实时活动开关切换。
    /// 每次对齐都会补足本轮预约名额（见 `CourseLiveActivityPlanner.schedulingCandidates`）。
    func autoUpdateActivity() {
        guard !isReconciling else {
            needsReconcile = true
            return
        }

        isReconciling = true

        Task {
            await reconcile()
            isReconciling = false

            if needsReconcile {
                needsReconcile = false
                autoUpdateActivity()
            }
        }
    }

    // MARK: - Private

    private func reconcile() async {
        guard isEnabled else {
            Logger.activityManager.info("实时活动已禁用。正在停止所有实时活动")
            await stopAllActivities()
            return
        }

        guard let data = MMKVHelper.CourseSchedule.activeCourseSchedule?.value.data else {
            Logger.activityManager.info("未找到课表数据。正在停止所有实时活动")
            await stopAllActivities()
            return
        }

        let now = Date()
        let plans = CourseLiveActivityPlanner.makePlans(
            semesterStartDate: data.semesterStartDate,
            now: now,
            courses: data.courses,
            weekCount: data.weekCount
        )

        Logger.activityManager.info("开始对齐课程实时活动，共 \(plans.count) 条排期")
        await makeStrategy().reconcile(plans: plans, now: now)
    }

    /// 结束所有实时活动（包含尚未触发的预约）
    ///
    /// 与 `hasActivity` / 并发名额核算（`isOngoing`）不同，这里要连 `.ended` 的活动一起结束：
    /// 按 `dismissalPolicy: .after(...)` 结束的卡片（「已下课」相位）仍会停留在锁屏上直到
    /// `dismissDate`，而关闭开关或清空课表时用户期望卡片立即消失；只有已经被用户划掉的
    /// `.dismissed` 活动完全由系统移除，无需重复结束。
    private func stopAllActivities() async {
        let activities = Activity<CourseStatusWidgetAttributes>.activities.filter { $0.activityState != .dismissed }
        guard !activities.isEmpty else { return }

        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        Logger.activityManager.info("已结束 \(activities.count) 个实时活动")
    }

    private func makeStrategy() -> ActivitySchedulingStrategy {
        if #available(iOS 26.0, *) {
            return ScheduledActivityStrategy()
        }
        return ForegroundActivityStrategy()
    }
}

extension Logger {
    static let activityManager = Logger(appCategory: "ActivityManager")
}

#endif

extension MMKVHelper {
    enum ActivityManager {
        @MMKVStorage(key: "GlobalVars.isLiveActivityEnabled", defaultValue: true)
        static var isEnabled: Bool
    }
}
