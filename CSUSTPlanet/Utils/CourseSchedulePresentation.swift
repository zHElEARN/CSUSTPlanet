//
//  CourseSchedulePresentation.swift
//  CSUSTPlanet
//

import CSUSTKit
import Foundation

enum TodayCourseFallbackReason {
    case noScheduledCourses
    case finishedAllCourses

    var message: String {
        switch self {
        case .noScheduledCourses:
            return "今天没有课程，好好休息吧"
        case .finishedAllCourses:
            return "今天的课程已经上完啦"
        }
    }
}

enum DailyCourseDisplayState {
    case today(courses: [(occurrence: CourseOccurrence, isCurrent: Bool)])
    case tomorrowPreview(reason: TodayCourseFallbackReason, courses: [CourseOccurrence])

    static func resolve(for data: CourseScheduleData, at now: Date) -> Self {
        let unfinishedCourses = ScheduleUtils.unfinishedCourses(
            at: now,
            semesterStartDate: data.semesterStartDate,
            courses: data.courses,
            weekCount: data.resolvedWeekCount
        )
        if !unfinishedCourses.isEmpty {
            return .today(courses: unfinishedCourses)
        }

        let todayCourses = ScheduleUtils.courses(
            on: now,
            semesterStartDate: data.semesterStartDate,
            courses: data.courses,
            weekCount: data.resolvedWeekCount
        )
        let reason: TodayCourseFallbackReason = todayCourses.isEmpty ? .noScheduledCourses : .finishedAllCourses
        let calendar = CourseSchedulePresentation.calendar
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return .tomorrowPreview(reason: reason, courses: [])
        }

        let tomorrowCourses = ScheduleUtils.courses(
            on: tomorrow,
            semesterStartDate: data.semesterStartDate,
            courses: data.courses,
            weekCount: data.resolvedWeekCount
        ).filter { CourseSchedulePresentation.sectionTimes(for: $0.session) != nil }
        return .tomorrowPreview(reason: reason, courses: tomorrowCourses)
    }
}

enum CourseSchedulePresentation {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }()

    static let monthFormatter = makeDateFormatter("M")
    static let dayFormatter = makeDateFormatter("d")
    static let dateFormatter = makeDateFormatter("yyyy-MM-dd")
    static let dateTimeFormatter = makeDateFormatter("yyyy-MM-dd HH:mm")

    static let semesterStartThreshold = 7
    static let courseScheduleTitle = "我的课表"
    static let emptyCourseScheduleText = "暂无课表数据"
    static let semesterNotStartedText = "学期未开始"
    static let semesterEndedText = "本学期已结束"
    static let tomorrowCoursesTitleText = "以下为明日课程"
    static let noScheduledCoursesTomorrowText = "明天也没课哦"

    private static let holidayMessages = [
        "好好享受假期吧！",
        "假期余额充足。",
        "今天只管玩！",
        "享受当下的闲暇时光吧！",
        "去看看外面的世界。",
        "休息是为了走更远的路。",
        "祝你今天玩得开心！",
        "假期就该轻松点。",
        "还没开学，再睡会？",
        "不赶时间，慢慢来。",
        "今天也是元气满满的一天！",
        "放下压力，轻松一下。",
        "生活不只有课表，还有远方。",
        "记得给心情放个假。",
        "难得清闲，读一本好书。",
        "保持热爱，奔赴山海。",
        "好心情是最好的良药。",
        "偷得浮生半日闲。",
        "愿你今天有个好梦。",
    ]

    static func semesterCountdownText(days: Int) -> String {
        "距离开学还有 \(days) 天"
    }

    static func holidayMessage(for date: Date) -> String {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        return holidayMessages[dayOfYear % holidayMessages.count]
    }

    static func sectionTimes(for session: EduHelper.ScheduleSession) -> (start: String, end: String)? {
        let times = ScheduleUtils.sectionTimeStrings
        guard session.startSection >= 1,
            session.startSection <= session.endSection,
            session.endSection <= times.count
        else {
            return nil
        }
        return (times[session.startSection - 1].start, times[session.endSection - 1].end)
    }

    private static func makeDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
