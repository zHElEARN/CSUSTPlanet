//
//  TodayCoursesEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/24.
//

import WidgetKit

struct TodayCoursesEntry: TimelineEntry {
    let date: Date
    let configuration: TodayCoursesIntent
    let data: CourseScheduleData?
}
