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
    @Environment(\.widgetFamily) var family

    var entry: TodayCoursesProvider.Entry

    // MARK: - Body

    var body: some View {
        Group {
            if let data = entry.data {
                VStack(spacing: 0) {
                    headerView(date: entry.date, data: data)

                    Divider().padding(.vertical, 4)

                    contentView(date: entry.date, data: data)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                emptyView
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "csustplanet://widgets/courseSchedule"))
    }

    // MARK: - Empty View

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))

            VStack(spacing: 4) {
                Text("暂无课表数据")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("请先在 App 中查询课表")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    func headerView(date: Date, data: CourseScheduleData) -> some View {
        HStack(alignment: .center, spacing: 6) {
            if family != .systemSmall {
                Text("当前课程")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)
                Text(data.semester ?? "默认学期")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            Text("周\(CourseScheduleUtil.getDayOfWeek(date).stringValue)")
                .font(.system(size: 14))
                .foregroundStyle(.red)

            Spacer()

            switch CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: date) {
            case .beforeSemester:
                Text("学期未开始")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            case .afterSemester:
                Text("学期已结束")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            case .inSemester:
                if let currentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.semesterStartDate, now: date) {
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
    }

    // MARK: - Content View

    @ViewBuilder
    func contentView(date: Date, data: CourseScheduleData) -> some View {
        switch CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: date) {
        case .beforeSemester:
            beforeSemesterView(date: date, data: data)
        case .afterSemester:
            Text("学期已结束")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        case .inSemester:
            inSemesterView(date: date, data: data)
        }
    }

    // MARK: - Before Semester View

    @ViewBuilder
    func beforeSemesterView(date: Date, data: CourseScheduleData) -> some View {
        VStack(spacing: 4) {
            Text("学期未开始")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            if let daysUntilStart = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: date) {
                if daysUntilStart > CourseScheduleUtil.semesterStartThreshold {
                    Text(CourseScheduleUtil.getHolidayMessage(for: date))
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text("还有 \(daysUntilStart) 天开学")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - In Semester View

    @ViewBuilder
    func inSemesterView(date: Date, data: CourseScheduleData) -> some View {
        GeometryReader { proxy in
            let colors = ColorUtil.getCourseColors(data.courses)
            let count = (family == .systemLarge ? 5 : 2)
            let courses = CourseScheduleUtil.getUnfinishedCourses(semesterStartDate: data.semesterStartDate, now: date, courses: data.courses)
                .prefix(count)

            let spacing: CGFloat = 4
            let height = (proxy.size.height - spacing * CGFloat(count - 1)) / CGFloat(count)

            if courses.isEmpty {
                Text("今天没有课程啦")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: spacing) {
                    ForEach(courses, id: \.course.id) { course in
                        courseRowView(courseDisplayInfo: course.course, colors: colors, isCurrent: course.isCurrent)
                            .frame(maxWidth: .infinity, maxHeight: height)
                    }
                }
            }
        }
    }

    // MARK: - Course Row View

    @ViewBuilder
    func courseRowView(courseDisplayInfo: CourseDisplayInfo, colors: [String: Color], isCurrent: Bool) -> some View {
        let color = colors[courseDisplayInfo.course.courseName] ?? .gray
        let startTime = CourseScheduleUtil.sectionTimeString[courseDisplayInfo.session.startSection - 1].0
        let endTime = CourseScheduleUtil.sectionTimeString[courseDisplayInfo.session.endSection - 1].1
        HStack(spacing: 2) {
            Rectangle()
                .frame(width: 4)
                .foregroundStyle(color)
                .cornerRadius(2)

            HStack(spacing: 0) {
                if family == .systemSmall {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(courseDisplayInfo.course.courseName)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        HStack(spacing: 4) {
                            Text(courseDisplayInfo.session.classroom ?? "无教室")
                                .font(.system(size: 12))
                                .fixedSize()
                                .lineLimit(1)
                            Text(courseDisplayInfo.course.teacher ?? "无教师")
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        Text("\(startTime) - \(endTime)")
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 2)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(courseDisplayInfo.course.courseName)
                                .font(.system(size: 16, weight: .bold))
                                .lineLimit(1)
                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        HStack(spacing: 4) {
                            Text(courseDisplayInfo.session.classroom ?? "无教室")
                                .font(.system(size: 16))
                                .fixedSize()
                                .lineLimit(1)
                            Text(courseDisplayInfo.course.teacher ?? "无教师")
                                .font(.system(size: 16))
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 2)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(startTime)
                            .font(.system(size: 16))
                        Text(endTime)
                            .font(.system(size: 16))
                    }
                    .padding(.trailing, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(color.opacity(0.1))
            .cornerRadius(4)
        }
    }
}
