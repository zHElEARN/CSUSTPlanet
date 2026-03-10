//
//  UrgentCoursesEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import WidgetKit

struct UrgentCoursesEntry: TimelineEntry {
    let date: Date
    let data: UrgentCoursesData?
    let lastUpdated: Date?

    static func mockEntry(courseCount: Int = 5, lastUpdated: Date = .now.addingTimeInterval(-3600)) -> UrgentCoursesEntry {
        let courses = [
            UrgentCoursesData.Course(name: "马克思主义基本原理课外实践", id: "1"),
            UrgentCoursesData.Course(name: "程序设计、算法与数据结构（三）", id: "2"),
            UrgentCoursesData.Course(name: "大学物理B（下）", id: "3"),
            UrgentCoursesData.Course(name: "大学物理实验B", id: "4"),
            UrgentCoursesData.Course(name: "测试作业", id: "5"),
        ]

        return UrgentCoursesEntry(
            date: .now,
            data: UrgentCoursesData(
                courses: Array(courses.prefix(courseCount))
            ),
            lastUpdated: lastUpdated
        )
    }
}
