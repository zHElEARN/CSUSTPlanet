//
//  WeeklyCoursesEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/7/25.
//

import CSUSTKit
import SwiftUI
import WidgetKit

struct WeeklyCoursesEntryView: View {
    @Environment(\.widgetFamily) var family

    var entry: WeeklyCoursesProvider.Entry

    // MARK: - Constants
    let colSpacing: CGFloat = 2
    let rowSpacing: CGFloat = 2
    let timeColWidth: CGFloat = 30

    // MARK: - Body

    var body: some View {
        Group {
            if let data = entry.data {
                let semesterStatus = data.semesterStatus(at: entry.date)
                VStack(spacing: 0) {
                    CourseWidgetHeaderView(family: family, title: "本周课程", date: entry.date, data: data, semesterStatus: semesterStatus, scheduleName: entry.scheduleName)

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
        case .inSemester(let week):
            inSemesterView(date: date, data: data, week: week)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - In Semester View

    @ViewBuilder
    func inSemesterView(date: Date, data: CourseScheduleData, week: Int) -> some View {
        let firstVisibleSection = firstVisibleSection(for: date)
        let courseColors = ColorUtil.getCourseColors(data.courses)
        let courses = ScheduleUtils.weeklyCourses(data.courses)[week] ?? []

        VStack(spacing: 4) {
            scheduleHeaderView(for: week, semesterStartDate: data.semesterStartDate)

            GeometryReader { geometry in
                // 动态计算高度，6小节中间有5个缝隙
                let availableHeight = geometry.size.height
                let dynamicSectionHeight = max(0, (availableHeight - (5 * rowSpacing)) / 6)

                ZStack(alignment: .topLeading) {
                    scheduleBackgroundView(firstVisibleSection: firstVisibleSection, sectionHeight: dynamicSectionHeight)

                    coursesOverlayView(courses: courses, firstVisibleSection: firstVisibleSection, courseColors: courseColors, sectionHeight: dynamicSectionHeight, geometryWidth: geometry.size.width)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Schedule Header View

    func scheduleHeaderView(for week: Int, semesterStartDate: Date) -> some View {
        let dates = ScheduleUtils.dates(ofWeek: week, semesterStartDate: semesterStartDate)

        return HStack(spacing: colSpacing) {
            // 左上角月份显示区
            VStack(alignment: .center, spacing: 0) {
                if let firstDate = dates.first {
                    Text(CourseSchedulePresentation.monthFormatter.string(from: firstDate))
                        .font(.system(size: 12, weight: .bold))
                    Text("月")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: timeColWidth)

            // 星期及日期圆圈
            ForEach(Array(zip(DayOfWeek.allCases, dates)), id: \.0) { day, date in
                let isToday = CourseSchedulePresentation.calendar.isDate(date, inSameDayAs: entry.date)
                VStack(spacing: 0) {
                    Text(day.chineseShortString)
                        .font(.system(size: 10))
                        .foregroundColor(isToday ? .accentColor : .secondary)
                        .fontWeight(isToday ? .bold : .medium)

                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : Color.clear)

                        Text(CourseSchedulePresentation.dayFormatter.string(from: date))
                            .font(.system(size: 12, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white : .primary)
                    }
                    .frame(width: 18, height: 18)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Schedule Background View

    func scheduleBackgroundView(firstVisibleSection: Int, sectionHeight: CGFloat) -> some View {
        HStack(spacing: colSpacing) {
            // 左侧时间列
            VStack(spacing: rowSpacing) {
                ForEach(firstVisibleSection..<firstVisibleSection + 6, id: \.self) { section in
                    VStack(spacing: 1) {
                        Text("\(section)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            if section - 1 < ScheduleUtils.sectionTimeStrings.count {
                                Text(ScheduleUtils.sectionTimeStrings[section - 1].start)
                                Text(ScheduleUtils.sectionTimeStrings[section - 1].end)
                            }
                        }
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                    }
                    .frame(width: timeColWidth, height: sectionHeight)
                }
            }

            // 右侧网格
            VStack(spacing: rowSpacing) {
                ForEach(firstVisibleSection..<firstVisibleSection + 6, id: \.self) { _ in
                    HStack(spacing: colSpacing) {
                        ForEach(1...7, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: sectionHeight)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Courses Overlay View

    private func coursesOverlayView(courses: [CourseOccurrence], firstVisibleSection: Int, courseColors: [String: Color], sectionHeight: CGFloat, geometryWidth: CGFloat) -> some View {
        let totalSpacingWidth = colSpacing * 7
        let dayColumnWidth = (geometryWidth - timeColWidth - totalSpacingWidth) / 7

        return ZStack(alignment: .topLeading) {
            ForEach(courses.indices, id: \.self) { index in
                let courseInfo = courses[index]
                let session = courseInfo.session
                if session.endSection >= firstVisibleSection,
                    session.startSection < firstVisibleSection + 6,
                    CourseSchedulePresentation.sectionTimes(for: session) != nil
                {
                    courseCardView(course: courseInfo.course, session: session, color: courseColors[courseInfo.course.courseName] ?? .gray)
                        .frame(width: dayColumnWidth)
                        .frame(height: calculateHeight(for: session, firstVisibleSection: firstVisibleSection, sectionHeight: sectionHeight))
                        .offset(
                            x: calculateXOffset(for: session.dayOfWeek, columnWidth: dayColumnWidth),
                            y: calculateYOffset(for: session, firstVisibleSection: firstVisibleSection, sectionHeight: sectionHeight)
                        )
                }
            }
        }
    }

    // MARK: - Course Card View

    @ViewBuilder
    func courseCardView(course: EduHelper.Course, session: EduHelper.ScheduleSession, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(course.courseName)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .truncationMode(.tail)

            Text("@" + (session.classroom ?? "无教室"))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            color
                .cornerRadius(4)
                .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
        )
        .clipped()
    }

    // MARK: - Methods

    func firstVisibleSection(for date: Date) -> Int {
        let calendar = CourseSchedulePresentation.calendar
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTimeInMinutes = hour * 60 + minute

        let endOfMajorSection1 = 9 * 60 + 40  // 09:40
        let endOfMajorSection2 = 11 * 60 + 50  // 11:50

        if currentTimeInMinutes <= endOfMajorSection1 {
            return 1  // 1-6 节
        } else if currentTimeInMinutes <= endOfMajorSection2 {
            return 3  // 3-8 节
        } else {
            return 5  // 5-10 节
        }
    }

    func calculateHeight(for session: EduHelper.ScheduleSession, firstVisibleSection: Int, sectionHeight: CGFloat) -> CGFloat {
        let start = max(session.startSection, firstVisibleSection)
        let end = min(session.endSection, firstVisibleSection + 5)
        let sections = CGFloat(end - start + 1)
        guard sections > 0 else { return 0 }
        return sections * sectionHeight + (sections - 1) * rowSpacing
    }

    func calculateYOffset(for session: EduHelper.ScheduleSession, firstVisibleSection: Int, sectionHeight: CGFloat) -> CGFloat {
        let start = max(session.startSection, firstVisibleSection)
        let y = CGFloat(start - firstVisibleSection)
        return y * sectionHeight + y * rowSpacing
    }

    func calculateXOffset(for day: DayOfWeek, columnWidth: CGFloat) -> CGFloat {
        let x = CGFloat(day.rawValue)
        return timeColWidth + colSpacing + (x * columnWidth) + (x * colSpacing)
    }
}
