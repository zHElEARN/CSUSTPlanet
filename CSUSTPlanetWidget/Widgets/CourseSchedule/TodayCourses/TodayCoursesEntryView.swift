//
//  TodayCoursesEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import SwiftUI
import WidgetKit

struct TodayCoursesEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily

    var entry: TodayCoursesProvider.Entry

    var body: some View {
        VStack {
            if let data = entry.data {
                HStack {
                    if widgetFamily != .systemSmall {
                        Text("今日剩余课程")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(data.semester ?? "默认学期")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Text("周\(CourseScheduleUtil.getDayOfWeek(entry.date).stringValue)")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)

                    Spacer()

                    switch CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: entry.date) {
                    case .beforeSemester:
                        Text("学期未开始")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    case .afterSemester:
                        Text("学期已结束")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    case .inSemester:
                        if let currentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.semesterStartDate, now: entry.date) {
                            Text("第 \(currentWeek) 周")
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                        } else {
                            Text("无法计算当前周")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                coursesView(data: data)
            } else {
                Text("请先在App中查询课表")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .widgetURL(URL(string: "csustplanet://widgets/courseSchedule"))
    }

    func coursesView(data: CourseScheduleData) -> some View {
        Group {
            switch CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: entry.date) {
            case .beforeSemester:
                VStack {
                    if let daysUntilStart = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: entry.date),
                        daysUntilStart > CourseScheduleUtil.semesterStartThreshold
                    {
                        Text(CourseScheduleUtil.getHolidayMessage(for: entry.date))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                        Text("学期未开始")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    } else {
                        Text("学期未开始")
                        if let daysUntilStart = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: entry.date) {
                            Text("还有 \(daysUntilStart) 天开学")
                                .font(.system(size: 12))
                                .foregroundStyle(.primary)
                                .padding(.top, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .afterSemester:
                Text("学期已结束")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            case .inSemester:
                let courseColors = ColorUtil.getCourseColors(data.courses)
                let courseDisplayInfos = CourseScheduleUtil.getUnfinishedCourses(semesterStartDate: data.semesterStartDate, now: entry.date, courses: data.courses)
                    .prefix(widgetFamily == .systemLarge ? 5 : 2)

                if courseDisplayInfos.isEmpty {
                    Text("今天已经没有课程啦")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(courseDisplayInfos, id: \.course.id) { courseDisplayInfo in
                            courseCard(courseDisplayInfo: courseDisplayInfo.course, courseColors: courseColors, isCurrent: courseDisplayInfo.isCurrent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
    }

    private func courseCard(courseDisplayInfo: CourseDisplayInfo, courseColors: [String: Color], isCurrent: Bool) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(courseDisplayInfo.course.courseName)
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)

                    if isCurrent {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.green)
                    }
                }
                HStack {
                    Text(courseDisplayInfo.session.classroom ?? "无教室")
                        .fixedSize()
                    Text(courseDisplayInfo.course.teacher ?? "无教师")
                }
                .font(.system(size: widgetFamily == .systemSmall ? 12 : 14))
                if widgetFamily == .systemSmall {
                    Text("\(CourseScheduleUtil.sectionTimeString[courseDisplayInfo.session.startSection - 1].0) - \(CourseScheduleUtil.sectionTimeString[courseDisplayInfo.session.endSection - 1].1)")
                        .font(.system(size: 12))
                }
            }
            if widgetFamily != .systemSmall {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(CourseScheduleUtil.sectionTimeString[courseDisplayInfo.session.startSection - 1].0)
                        .font(.system(size: 16))
                    Text(CourseScheduleUtil.sectionTimeString[courseDisplayInfo.session.endSection - 1].1)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50)
        .background((courseColors[courseDisplayInfo.course.courseName] ?? .gray).opacity(0.1))
        .cornerRadius(4)
        .overlay(
            Rectangle()
                .frame(width: 4)
                .foregroundStyle(courseColors[courseDisplayInfo.course.courseName] ?? .gray)
                .cornerRadius(2)
                .padding(.leading, -8),
            alignment: .leading
        )
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
