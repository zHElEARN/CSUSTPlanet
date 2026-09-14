//
//  CourseLiveActivityPlanner.swift
//  CSUSTPlanet
//
//  Created by 韦亦航 on 2026/9/14.
//

#if os(iOS)

import CSUSTKit
import Foundation

/// 单节课的实时活动排期计划
struct CourseActivityPlan: Equatable, Sendable {
    /// 课程名称
    let courseName: String
    /// 教师
    let teacher: String
    /// 教室
    let classroom: String?

    /// 上课时间
    let startDate: Date
    /// 下课时间
    let endDate: Date
    /// 系统启动实时活动并弹出提醒的时间（上课前 20 分钟）
    let triggerDate: Date
    /// 系统把实时活动标记为 stale 的时间（上课时间）
    let staleDate: Date
    /// App 清理实时活动的时间（下课后 5 分钟）
    let dismissDate: Date

    /// 提醒标题
    var alertTitle: String {
        "即将上课"
    }

    /// 提醒正文
    var alertBody: String {
        let leadTimeMinutes = Int(CourseLiveActivityPlanner.triggerLeadTime / 60)
        guard let classroom, !classroom.isEmpty else {
            return "「\(courseName)」\(leadTimeMinutes) 分钟后开始"
        }
        return "「\(courseName)」\(leadTimeMinutes) 分钟后开始 · \(classroom)"
    }
}

extension CourseActivityPlan {
    /// 实时活动的静态属性
    var attributes: CourseStatusWidgetAttributes {
        CourseStatusWidgetAttributes(
            courseName: courseName,
            teacher: teacher,
            classroom: classroom,
            startDate: startDate,
            endDate: endDate,
            triggerDate: triggerDate,
            dismissDate: dismissDate
        )
    }

    /// 判断已存在的实时活动是否属于该排期计划
    ///
    /// 展示字段（课程、教师、教室、时间）或触发时间不一致时视为需要重建。
    /// 清理时间不参与比对，避免下一节课变化时重建已经展示过的活动。
    ///
    /// 注意：同一天内同名、同教师、同教室、同时段的重复 session 在属性上完全一致，这里无法区分；
    /// 去重由 `CourseLiveActivityPlanner.makePlans`（按身份键合并）与策略层（循环内复查已有活动）负责。
    func matches(_ attributes: CourseStatusWidgetAttributes) -> Bool {
        courseName == attributes.courseName
            && teacher == attributes.teacher
            && classroom == attributes.classroom
            && startDate == attributes.startDate
            && endDate == attributes.endDate
            && triggerDate == attributes.triggerDate
    }

    /// 排期的身份键：属性完全相同的重复 session 视为同一节课
    struct Identity: Hashable {
        let courseName: String
        let teacher: String
        let classroom: String?
        let startDate: Date
        let endDate: Date
    }

    var identity: Identity {
        Identity(
            courseName: courseName,
            teacher: teacher,
            classroom: classroom,
            startDate: startDate,
            endDate: endDate
        )
    }
}

/// 课程实时活动的排期计算
///
/// 该类型只做纯计算，不接触 `ActivityKit`，便于单独验证时间参数。
enum CourseLiveActivityPlanner {
    /// 上课前提前启动实时活动的时间（与 widget 共享同一份常量）
    static let triggerLeadTime = CourseStatusLiveActivityTiming.triggerLeadTime
    /// 下课后保留实时活动的时间（与 widget 共享同一份常量）
    static let dismissDelay = CourseStatusLiveActivityTiming.dismissDelay
    /// 清理时间与下一节课触发时间之间至少保留的间隔
    static let nextCourseSafeGap: TimeInterval = 60
    /// 下课后至少保留实时活动的时间（清理时间不得早于「下课时间 + 该值」）
    static let minimumPostClassRetention: TimeInterval = 60
    /// 默认排期的日期偏移：今天起的一整周
    ///
    /// 该窗口只决定为哪些课程准备排期，供对账与前台补齐使用；真正向系统预约的数量由
    /// `scheduledActivityLimit` 限制，不再按窗口全量预约。窗口覆盖到一周是为了让「周日打开一次 App」
    /// 也能为周一的第一节课预约提醒；系统是否接受提前数日的预约仍需真机确认。
    static let defaultDayOffsets = Array(0...6)
    /// 同时向系统预约的实时活动数量上限（含正在上课的那节，以及改课表后遗留的旧活动）
    ///
    /// 系统对同时在跑的实时活动（含尚未触发的预约）有数量上限，但上限数值 Apple 未公开，
    /// 部分开发者（OneSignal,PushWoosh,京东云等）过去实测数据为4-5个，因此保守取最近 4 节；
    /// 其余课程由 App 每次进入前台时按触发时间正序补齐。
    static let scheduledActivityLimit = 4
    /// 无教师信息时的占位文案
    static let unknownTeacherText = "无老师"

    /// 生成实时活动排期计划
    /// - Parameters:
    ///   - semesterStartDate: 学期开始日期
    ///   - now: 当前时间
    ///   - courses: 当前生效课表的课程
    ///   - weekCount: 课表总周数，nil 时使用默认值
    ///   - dayOffsets: 需要排期的日期偏移，默认今天起的一整周
    /// - Returns: 按触发时间正序排列、且已按身份键去重的排期计划，已过滤展示窗口（下课后 5 分钟）已结束的课程
    static func makePlans(
        semesterStartDate: Date,
        now: Date,
        courses: [EduHelper.Course],
        weekCount: Int? = nil,
        dayOffsets: [Int] = defaultDayOffsets
    ) -> [CourseActivityPlan] {
        var plans: [CourseActivityPlan] = []
        var seenIdentities: Set<CourseActivityPlan.Identity> = []

        for dayOffset in dayOffsets {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let slices = CourseScheduleUtil.getCoursesForDate(
                semesterStartDate: semesterStartDate,
                targetDate: targetDate,
                courses: courses,
                weekCount: weekCount
            )
            .compactMap { courseInfo -> CourseSlice? in
                guard let dates = courseDates(of: courseInfo.session, on: targetDate) else { return nil }
                return CourseSlice(courseInfo: courseInfo, startDate: dates.startDate, endDate: dates.endDate)
            }
            .sorted { $0.startDate < $1.startDate }

            for (index, slice) in slices.enumerated() {
                let nextCourseStartDate = slices.indices.contains(index + 1) ? slices[index + 1].startDate : nil
                let plan = makePlan(slice: slice, nextCourseStartDate: nextCourseStartDate)
                // 已下课但仍在展示窗口内的课程需要保留，用于补正“已下课”状态与清理
                guard plan.dismissDate > now else { continue }
                // 去重：自定义课表允许重复添加同一节课，学校接口也可能返回重复 session，
                // 两条属性完全相同的排期无法区分，合并后只占一个预约名额
                guard seenIdentities.insert(plan.identity).inserted else { continue }
                plans.append(plan)
            }
        }

        return plans.sorted { $0.triggerDate < $1.triggerDate }
    }

    /// 选取本次需要向系统预约的课程排期
    ///
    /// 只取触发时间最近的 `limit` 节尚未结束的课程（正在上课的那节也占名额），其余课程留待 App
    /// 下次进入前台时补齐；已下课但仍在展示窗口内的排期不参与预约，只由对账负责补正与清理。
    ///
    /// 对账始终以 `makePlans` 的完整窗口为依据，因此跌出预约名额的课程不会被误清理。
    /// - Parameters:
    ///   - plans: 完整排期计划（按触发时间正序）
    ///   - now: 本次对齐的时间基准
    ///   - limit: 本次可预约的活动数量上限
    /// - Returns: 本次需要预约的排期（按触发时间正序）
    static func schedulingCandidates(
        plans: [CourseActivityPlan],
        now: Date,
        limit: Int = scheduledActivityLimit
    ) -> [CourseActivityPlan] {
        guard limit > 0 else { return [] }
        return Array(plans.lazy.filter { $0.endDate > now }.prefix(limit))
    }

    /// 扣除已经进行中的实时活动后，本轮还能向系统预约的数量
    ///
    /// 系统的并发上限按应用内实际存在的活动计算，改课表后遗留、已不在当前排期里的活动同样占名额，
    /// 因此扣减基准必须是「进行中的活动总数」，而不是「本轮窗口内的活动数」。
    /// - Parameters:
    ///   - ongoingCount: 当前进行中（`pending` / `active` / `stale`）的实时活动数量
    ///   - limit: 同时存在的活动数量上限
    /// - Returns: 本轮最多还能预约的活动数量，已用尽时返回 0
    static func remainingScheduleQuota(
        ongoingCount: Int,
        limit: Int = scheduledActivityLimit
    ) -> Int {
        max(0, limit - ongoingCount)
    }

    /// 计算实时活动的清理时间
    ///
    /// `dismissDate = min(下课时间 + 下课后保留时长, 下一节课触发时间 − 安全间隔)`；
    /// 若课间过短导致结果早于「下课时间 + 下课后最小保留时长」，则回退为该最小值。
    /// - Parameters:
    ///   - endDate: 下课时间
    ///   - nextCourseStartDate: 下一节课的上课时间，无下一节课时传 nil
    static func dismissalDate(endDate: Date, nextCourseStartDate: Date?) -> Date {
        let defaultDate = endDate.addingTimeInterval(dismissDelay)
        guard let nextCourseStartDate else { return defaultDate }

        let latestAllowedDate = nextCourseStartDate.addingTimeInterval(-triggerLeadTime - nextCourseSafeGap)
        return max(min(defaultDate, latestAllowedDate), endDate.addingTimeInterval(minimumPostClassRetention))
    }

    // MARK: - 内部实现

    /// 某一天中的一节课
    private struct CourseSlice {
        let courseInfo: CourseDisplayInfo
        let startDate: Date
        let endDate: Date
    }

    private static func makePlan(slice: CourseSlice, nextCourseStartDate: Date?) -> CourseActivityPlan {
        CourseActivityPlan(
            courseName: slice.courseInfo.course.courseName,
            teacher: slice.courseInfo.course.teacher ?? unknownTeacherText,
            classroom: slice.courseInfo.session.classroom,
            startDate: slice.startDate,
            endDate: slice.endDate,
            triggerDate: slice.startDate.addingTimeInterval(-triggerLeadTime),
            staleDate: slice.startDate,
            dismissDate: dismissalDate(endDate: slice.endDate, nextCourseStartDate: nextCourseStartDate)
        )
    }

    private static func courseDates(
        of session: EduHelper.ScheduleSession,
        on targetDate: Date
    ) -> (startDate: Date, endDate: Date)? {
        let startSectionIndex = session.startSection - 1
        let endSectionIndex = session.endSection - 1
        guard startSectionIndex >= 0, startSectionIndex < CourseScheduleUtil.sectionTimeString.count,
            endSectionIndex >= 0, endSectionIndex < CourseScheduleUtil.sectionTimeString.count
        else { return nil }

        guard
            let startDate = date(on: targetDate, timeString: CourseScheduleUtil.sectionTimeString[startSectionIndex].0),
            let endDate = date(on: targetDate, timeString: CourseScheduleUtil.sectionTimeString[endSectionIndex].1)
        else { return nil }

        // 脏数据（`endSection < startSection`）会构造出上界小于下界的区间，让 widget 渲染崩溃；
        // 该节课直接不生成排期
        guard endDate > startDate else { return nil }

        return (startDate: startDate, endDate: endDate)
    }

    private static func date(on targetDate: Date, timeString: String) -> Date? {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return nil }
        return calendar.date(bySettingHour: components[0], minute: components[1], second: 0, of: targetDate)
    }

    /// 课程时间均以长沙当地时间为准
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = CourseScheduleUtil.courseTimeZone
        return calendar
    }()
}

#endif
