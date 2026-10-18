//
//  CourseSchedulePreviewData.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import CSUSTKit
import Foundation

enum CourseSchedulePreviewData {
    static let semesterStartDate = Date(timeIntervalSince1970: 1_781_366_400)
    static let weekCount = 20

    // MARK: - 单节课

    static let sessionA = EduHelper.ScheduleSession(
        weeks: [1],
        startSection: 1,
        endSection: 2,
        dayOfWeek: .monday,
        classroom: "教室A"
    )

    static let sessionB = EduHelper.ScheduleSession(
        weeks: [1],
        startSection: 5,
        endSection: 6,
        dayOfWeek: .wednesday,
        classroom: "教室B"
    )

    static let courseA = EduHelper.Course(
        courseName: "课程A",
        groupName: nil,
        teacher: "老师A",
        sessions: [sessionA]
    )

    static let courseB = EduHelper.Course(
        courseName: "课程B",
        groupName: nil,
        teacher: "老师B",
        sessions: [sessionB]
    )

    // MARK: - 时间冲突

    static let overlappingSession = EduHelper.ScheduleSession(
        weeks: [1],
        startSection: 1,
        endSection: 4,
        dayOfWeek: .monday,
        classroom: "教室B"
    )

    static let overlappingCourse = EduHelper.Course(
        courseName: "课程B",
        groupName: nil,
        teacher: "老师B",
        sessions: [overlappingSession]
    )

    static let conflictCourses: [CourseDisplayInfo] = [
        CourseDisplayInfo(course: courseA, session: sessionA),
        CourseDisplayInfo(course: overlappingCourse, session: overlappingSession),
    ]

    // MARK: - 整周课程

    static let overlaySessions: [EduHelper.ScheduleSession] = [
        sessionA,
        overlappingSession,
        EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 8, dayOfWeek: .tuesday, classroom: "教室C"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 7, endSection: 9, dayOfWeek: .tuesday, classroom: "教室D"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 9, endSection: 10, dayOfWeek: .tuesday, classroom: "教室E"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 3, endSection: 4, dayOfWeek: .wednesday, classroom: "教室F"),
        EduHelper.ScheduleSession(weeks: [1], startSection: 5, endSection: 6, dayOfWeek: .wednesday, classroom: "教室G"),
    ]

    static let overlayCourses: [EduHelper.Course] = overlaySessions.enumerated().map { index, session in
        EduHelper.Course(
            courseName: "课程\(index + 1)",
            groupName: nil,
            teacher: "老师\(index + 1)",
            sessions: [session]
        )
    }

    static let overlayWeeklyCourses: [Int: [CourseDisplayInfo]] = [
        1: overlayCourses.map { CourseDisplayInfo(course: $0, session: $0.sessions[0]) }
    ]

    static let overlayCourseColors = ColorUtil.getCourseColors(overlayCourses)

    // MARK: - 控制栏

    static let remarks: [String] = [
        "软件系统开发实训 贺紫平 17-19周",
        "习近平新时代中国特色社会主义思想概论课外实践 刘绍云 27周",
        "毛泽东思想和中国特色社会主义理论体系概论课外实践 张慧娟 25周",
    ]

    static let subtitle = "2024-2025-1"
    static let currentWeek = 8
    static let realCurrentWeek = 16

    // MARK: - 学期选择

    static let semesterOptions = ["2024-2025-1", "2024-2025-2"]

    // MARK: - 自定义课表

    static let scheduleName = "我的课表 1"

    static let customSchedule = CustomCourseScheduleGRDB(
        id: "preview-id",
        name: "我的课表 1",
        semesterStartDate: .now,
        weekCount: 20,
        remarks: "",
        createdAt: .now
    )

    static let customSchedules: [CustomCourseScheduleGRDB] = [
        CustomCourseScheduleGRDB(
            id: "1",
            name: "我的课表 1",
            semesterStartDate: .now,
            weekCount: 20,
            remarks: "",
            createdAt: .now
        ),
        CustomCourseScheduleGRDB(
            id: "2",
            name: "考研冲刺",
            semesterStartDate: .now,
            weekCount: 20,
            remarks: "",
            createdAt: .now
        ),
    ]

    static let currentCustomScheduleID = "2"

    static let customCourse = CustomCourseGRDB(
        id: "preview-course",
        scheduleId: "preview-schedule",
        courseName: "高等数学",
        teacher: "刘文正",
        groupName: "08"
    )

    static let customSessions: [CustomSessionGRDB] = [
        CustomSessionGRDB(
            id: "1",
            courseId: "preview-course",
            dayOfWeek: 1,
            startSection: 5,
            endSection: 6,
            classroom: "金13-106",
            weeks: JSONIntArray([1, 2, 3, 4, 5, 6, 7, 8])
        ),
        CustomSessionGRDB(
            id: "2",
            courseId: "preview-course",
            dayOfWeek: 3,
            startSection: 1,
            endSection: 2,
            classroom: nil,
            weeks: JSONIntArray([1, 2, 3, 4, 5, 6, 7, 8])
        ),
    ]
}
