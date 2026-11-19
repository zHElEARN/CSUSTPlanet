//
//  ActivityManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

#if os(iOS)

import ActivityKit
import CSUSTKit
import Combine
import Foundation
import OSLog

@MainActor
@Observable
final class ActivityManager {
    static let shared = ActivityManager()

    private var cancellables = Set<AnyCancellable>()

    var activity: Activity<CourseStatusWidgetAttributes>? = nil

    var isEnabled: Bool {
        didSet {
            MMKVHelper.ActivityManager.isEnabled = isEnabled
            autoUpdateActivity()
        }
    }

    private init() {
        isEnabled = MMKVHelper.ActivityManager.isEnabled
        startObservingLifecycle()

        guard activity == nil, let existingActivity = Activity<CourseStatusWidgetAttributes>.activities.first else { return }
        self.activity = existingActivity

        Logger.activityManager.info("已恢复现有的实时活动")
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

    func autoUpdateActivity() {
        guard isEnabled else {
            Logger.activityManager.info("实时活动已禁用。正在停止所有活跃活动")
            stopActivity()
            return
        }

        let currentDate = Date()
        guard let data = MMKVHelper.CourseSchedule.activeCourseSchedule?.value.data else {
            stopActivity()
            return
        }

        if let occurrence = ScheduleUtils.relevantCourse(
            at: currentDate,
            semesterStartDate: data.semesterStartDate,
            courses: data.courses,
            weekCount: data.resolvedWeekCount
        ),
            let weekStart = ScheduleDateUtil.calendar.dateInterval(of: .weekOfYear, for: currentDate)?.start,
            let courseDates = ScheduleUtils.timeRange(of: occurrence.session, inWeek: 1, semesterStartDate: weekStart)
        {
            let attributes = CourseStatusWidgetAttributes(
                courseName: occurrence.course.courseName,
                teacher: occurrence.course.teacher,
                classroom: occurrence.session.classroom,
                startDate: courseDates.startDate,
                endDate: courseDates.endDate
            )

            if let existingActivity = self.activity, existingActivity.activityState == .active {
                if existingActivity.attributes == attributes {
                    Logger.activityManager.info("实时活动状态正确。正在强制刷新 UI")
                    Task {
                        let content = ActivityContent(state: CourseStatusWidgetAttributes.ContentState(now: .now), staleDate: nil)
                        await existingActivity.update(content)
                    }
                } else {
                    Logger.activityManager.info("发现过期的活动。正在替换为新活动")
                    try? startActivity(attributes)
                }
            } else {
                Logger.activityManager.info("未找到活跃活动。正在启动新活动")
                try? startActivity(attributes)
            }
        } else {
            Logger.activityManager.info("未找到相关课程。正在停止所有活跃活动")
            stopActivity()
        }
    }

    private func startActivity(_ attributes: CourseStatusWidgetAttributes) throws {
        stopActivity()

        let content = ActivityContent(state: CourseStatusWidgetAttributes.ContentState(now: .now), staleDate: nil)

        do {
            let newActivity = try Activity.request(
                attributes: attributes,
                content: content
            )
            self.activity = newActivity
            Logger.activityManager.info("已为课程启动实时活动：\(attributes.courseName)")
        } catch {
            Logger.activityManager.error("启动实时活动失败: \(error.localizedDescription)")
            throw error
        }
    }

    private func stopActivity() {
        guard let activityToStop = activity else { return }

        Task {
            await activityToStop.end(nil, dismissalPolicy: .immediate)
            if self.activity?.id == activityToStop.id {
                self.activity = nil
                Logger.activityManager.info("实时活动已停止")
            }
        }
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
