//
//  PhysicsExperimentPreviewData.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import CSUSTKit
import Foundation

enum PhysicsExperimentGradePreviewData {
    static let grades: [PhysicsExperimentHelper.CourseGrade] = [
        makeGrade("PHYS1001", "大学物理实验", "用示波器观测周期性电信号", 92, 88, 95, 91),
        makeGrade("PHYS1001", "大学物理实验", "分光计的调节与使用", 85, 90, nil, 87),
        makeGrade("PHYS1001", "大学物理实验", "光电效应测普朗克常数", nil, nil, nil, 78),
    ]

    private static func makeGrade(
        _ courseCode: String,
        _ courseName: String,
        _ itemName: String,
        _ previewGrade: Int?,
        _ operationGrade: Int?,
        _ reportGrade: Int?,
        _ totalGrade: Int
    ) -> PhysicsExperimentHelper.CourseGrade {
        PhysicsExperimentHelper.CourseGrade(
            courseCode: courseCode,
            courseName: courseName,
            itemName: itemName,
            previewGrade: previewGrade,
            operationGrade: operationGrade,
            reportGrade: reportGrade,
            totalGrade: totalGrade
        )
    }
}

enum PhysicsExperimentSchedulePreviewData {
    static let courses: [PhysicsExperimentHelper.Course] = [
        makeCourse(1, "用示波器观测周期性电信号", "周一第3批", "张三", "工科楼 A301", -7, 14, 17, .monday),
        makeCourse(2, "分光计的调节与使用", "周三第1批", "李四", "工科楼 B205", 0, 8, 11, .wednesday),
        makeCourse(3, "光电效应测普朗克常数", "周五第2批", "王五", "工科楼 A104", 3, 14, 17, .friday),
    ]

    private static func makeCourse(
        _ id: Int,
        _ name: String,
        _ batch: String,
        _ teacher: String,
        _ location: String,
        _ dayOffset: Int,
        _ startHour: Int,
        _ endHour: Int,
        _ dayOfWeek: EduHelper.DayOfWeek
    ) -> PhysicsExperimentHelper.Course {
        PhysicsExperimentHelper.Course(
            id: id,
            name: name,
            batch: batch,
            teacher: teacher,
            location: location,
            startTime: makeDate(dayOffset: dayOffset, hour: startHour),
            endTime: makeDate(dayOffset: dayOffset, hour: endHour),
            classHours: endHour - startHour,
            week: 1,
            dayOfWeek: dayOfWeek
        )
    }

    private static func makeDate(dayOffset: Int, hour: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}
