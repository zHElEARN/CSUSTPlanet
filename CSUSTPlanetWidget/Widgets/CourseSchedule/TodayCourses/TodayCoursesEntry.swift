//
//  TodayCoursesEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/24.
//

import CSUSTKit
import WidgetKit

private let courses = [
    EduHelper.Course(
        courseName: "美术鉴赏(艺术及其他)",
        groupName: nil,
        teacher: "赵晖(14)讲师",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 9, endSection: 10, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-215")]
    ),
    EduHelper.Course(
        courseName: "离散结构",
        groupName: nil,
        teacher: "肖红光副教授",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 1, endSection: 2, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-106")]
    ),
    EduHelper.Course(
        courseName: "写作与沟通",
        groupName: nil,
        teacher: "陈璐（12）副教授",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 3, endSection: 4, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金6-304")]
    ),
    EduHelper.Course(
        courseName: "程序设计、算法与数据结构（三）",
        groupName: nil,
        teacher: "陈曦(小)副教授",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 5, endSection: 6, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-107")]
    ),
    EduHelper.Course(
        courseName: "大学物理实验B",
        groupName: nil,
        teacher: "蔡爱军讲师",
        sessions: [EduHelper.ScheduleSession(weeks: [2], startSection: 7, endSection: 8, dayOfWeek: EduHelper.DayOfWeek.wednesday, classroom: "金12-500")]
    ),
]

struct TodayCoursesEntry: TimelineEntry {
    let date: Date
    let configuration: TodayCoursesIntent
    let data: CourseScheduleData?

    static let mockEntry = {
        let semesterDateFormatter = DateFormatter()
        semesterDateFormatter.dateFormat = "yyyy-MM-dd"

        let data = CourseScheduleData(semester: "2025-2026-1", semesterStartDate: semesterDateFormatter.date(from: "2025-09-07")!, courses: courses)

        let timeDateFormatter = DateFormatter()
        timeDateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        return TodayCoursesEntry(
            date: timeDateFormatter.date(from: "2025-09-17 04:00")!,
            configuration: TodayCoursesIntent(),
            data: data
        )
    }()
}
