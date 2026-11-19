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
                let semesterStatus = data.semesterStatus(at: entry.date)
                VStack(spacing: 0) {
                    CourseWidgetHeaderView(
                        family: family, title: CourseSchedulePresentation.courseScheduleTitle, date: entry.date, data: data, semesterStatus: semesterStatus, scheduleName: entry.scheduleName
                    )

                    Divider().padding(.vertical, 4)

                    contentView(date: entry.date, data: data, semesterStatus: semesterStatus)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                CourseWidgetEmptyView()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "csustplanet://app/features/course-schedule"))
    }

    // MARK: - Content View

    @ViewBuilder
    func contentView(date: Date, data: CourseScheduleData, semesterStatus: SemesterStatus) -> some View {
        switch semesterStatus {
        case .beforeSemester(let days):
            CourseWidgetBeforeSemesterView(date: date, daysUntilStart: days)
        case .afterSemester:
            CourseWidgetAfterSemesterView()
        case .inSemester:
            inSemesterView(data: data, dailyCourseDisplayState: .resolve(for: data, at: date))
        }
    }

    // MARK: - In Semester View

    @ViewBuilder
    func inSemesterView(data: CourseScheduleData, dailyCourseDisplayState: DailyCourseDisplayState) -> some View {
        GeometryReader { proxy in
            let colors = ColorUtil.getCourseColors(data.courses)
            let displayLimit = (family == .systemLarge ? 5 : 2)

            switch dailyCourseDisplayState {
            case .today(let courses):
                courseListView(
                    courses: Array(courses.prefix(displayLimit)),
                    colors: colors,
                    availableHeight: proxy.size.height,
                    slotCount: displayLimit
                )
            case .tomorrowPreview(let reason, let courses):
                if !courses.isEmpty {
                    tomorrowPreviewView(
                        courses: courses,
                        colors: colors,
                        availableHeight: proxy.size.height,
                        displayLimit: displayLimit
                    )
                } else {
                    tomorrowEmptyStateView(reason: reason)
                }
            }
        }
    }

    @ViewBuilder
    func courseListView(
        courses: [(occurrence: CourseOccurrence, isCurrent: Bool)],
        colors: [String: Color],
        availableHeight: CGFloat,
        slotCount: Int
    ) -> some View {
        let spacing: CGFloat = 4
        let height = max(0, (availableHeight - spacing * CGFloat(max(slotCount - 1, 0))) / CGFloat(max(slotCount, 1)))

        VStack(spacing: spacing) {
            ForEach(courses.indices, id: \.self) { index in
                let (occurrence, isCurrent) = courses[index]
                if let times = CourseSchedulePresentation.sectionTimes(for: occurrence.session) {
                    courseRowView(courseDisplayInfo: occurrence, times: times, colors: colors, isCurrent: isCurrent)
                        .frame(maxWidth: .infinity, maxHeight: height)
                }
            }
        }
    }

    @ViewBuilder
    func tomorrowPreviewView(
        courses: [CourseOccurrence],
        colors: [String: Color],
        availableHeight: CGFloat,
        displayLimit: Int
    ) -> some View {
        let visibleCourses = courses.prefix(displayLimit)
        let spacing: CGFloat = family == .systemLarge ? 4 : 3
        let summaryHeight: CGFloat = family == .systemLarge ? 14 : 12

        VStack(alignment: .leading, spacing: spacing) {
            tomorrowSummaryView(courseCount: courses.count)
                .frame(height: summaryHeight, alignment: .leading)

            courseListView(
                courses: visibleCourses.map { (occurrence: $0, isCurrent: false) },
                colors: colors,
                availableHeight: max(0, availableHeight - summaryHeight - spacing),
                slotCount: displayLimit
            )
        }
    }

    @ViewBuilder
    func tomorrowSummaryView(courseCount: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(CourseSchedulePresentation.tomorrowCoursesTitleText)")
                .foregroundStyle(.red)
                .padding(.trailing, 4)
            Text("共")
            Text("\(courseCount)")
                .foregroundStyle(Color.accentColor)
            Text("节课程")
        }
        .minimumScaleFactor(0.8)
        .font(.system(size: family == .systemLarge ? 11 : 10, weight: .bold))
        .lineLimit(1)
    }

    @ViewBuilder
    func tomorrowEmptyStateView(reason: TodayCourseFallbackReason) -> some View {
        VStack(spacing: 4) {
            Text(reason.message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(family == .systemSmall ? 2 : 1)
                .minimumScaleFactor(0.8)

            Text(CourseSchedulePresentation.noScheduledCoursesTomorrowText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Course Row View

    @ViewBuilder
    func courseRowView(courseDisplayInfo: CourseOccurrence, times: (start: String, end: String), colors: [String: Color], isCurrent: Bool) -> some View {
        let color = colors[courseDisplayInfo.course.courseName] ?? .gray
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
                                .font(.system(size: 13, weight: .bold))
                                .lineLimit(1)
                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        HStack(spacing: 4) {
                            Text(courseDisplayInfo.session.classroom ?? "无教室")
                                .font(.system(size: 11))
                                .fixedSize()
                                .lineLimit(1)
                            Text(courseDisplayInfo.course.teacher ?? "无教师")
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                        Text("\(times.start) - \(times.end)")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 2)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(courseDisplayInfo.course.courseName)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 7, height: 7)
                            }
                        }
                        HStack(spacing: 4) {
                            Text(courseDisplayInfo.session.classroom ?? "无教室")
                                .font(.system(size: 14))
                                .fixedSize()
                                .lineLimit(1)
                            Text(courseDisplayInfo.course.teacher ?? "无教师")
                                .font(.system(size: 14))
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 2)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(times.start)
                            .font(.system(size: 15))
                        Text(times.end)
                            .font(.system(size: 15))
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
