//
//  CourseOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseOverviewView: View {
    @State private var viewModel = CourseOverviewViewModel()
    @Environment(Router.self) private var router
    @State private var selectedCourse: CourseOccurrence?

    var body: some View {
        Button(action: { router.open(AppRoutes.courseSchedule.entry()) }) {
            CustomGroupBox {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    cardContent(now: context.date)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: courseDetailBinding) { [selectedCourse] in
            if let selectedCourse {
                NavigationStack {
                    CourseScheduleDetailView(
                        course: selectedCourse.course,
                        session: selectedCourse.session,
                        isToolbarPresented: true,
                    )
                }
            }
        }
    }

    private var courseDetailBinding: Binding<Bool> {
        Binding(
            get: { selectedCourse != nil },
            set: { isPresented in
                if !isPresented {
                    selectedCourse = nil
                }
            }
        )
    }

    @ViewBuilder
    private func cardContent(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(CourseSchedulePresentation.courseScheduleTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Text(viewModel.semesterInfoText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            contentView(now: now)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func contentView(now: Date) -> some View {
        switch viewModel.courseDisplayState(at: now) {
        case .loading:
            EmptyCourseContentView(text: CourseSchedulePresentation.emptyCourseScheduleText)

        case .beforeSemester(let days):
            if days > CourseSchedulePresentation.semesterStartThreshold {
                EmptyCourseContentView(
                    text: CourseSchedulePresentation.holidayMessage(for: now),
                    subtitle: CourseSchedulePresentation.semesterNotStartedText
                )
            } else {
                EmptyCourseContentView(
                    text: CourseSchedulePresentation.semesterNotStartedText,
                    subtitle: CourseSchedulePresentation.semesterCountdownText(days: days)
                )
            }

        case .afterSemester:
            EmptyCourseContentView(text: CourseSchedulePresentation.semesterEndedText)

        case .inSemester(let dailyCourseState):
            switch dailyCourseState {
            case .today(let courses):
                CourseListView(
                    courses: courses,
                    onSelect: { selectedCourse = $0 }
                )
            case .tomorrowPreview(let reason, let courses):
                if !courses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        TomorrowPreviewStatusView(
                            text: reason.message,
                            courseCount: courses.count
                        )

                        CourseListView(
                            courses: courses.map { (occurrence: $0, isCurrent: false) },
                            onSelect: { selectedCourse = $0 }
                        )
                    }
                } else {
                    EmptyCourseContentView(
                        text: reason.message,
                        subtitle: CourseSchedulePresentation.noScheduledCoursesTomorrowText
                    )
                }
            }
        }
    }
}

private struct CourseListView: View {
    let courses: [(occurrence: CourseOccurrence, isCurrent: Bool)]
    let onSelect: (CourseOccurrence) -> Void

    private var courseColors: [String: Color] {
        ColorUtil.getCourseColors(courses.map { $0.occurrence.course })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(courses.indices, id: \.self) { index in
                let item = courses[index]
                CourseRowView(
                    courseInfo: item.occurrence,
                    isCurrent: item.isCurrent,
                    accentColor: courseColors[item.occurrence.course.courseName] ?? .blue,
                    onTap: { onSelect(item.occurrence) }
                )
            }
        }
    }
}

private struct TomorrowPreviewStatusView: View {
    let text: String
    let courseCount: Int

    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .padding(.trailing, 8)
            Text(CourseSchedulePresentation.tomorrowCoursesTitleText)
                .foregroundStyle(.red)
                .padding(.trailing, 8)
            Text("共")
            Text("\(courseCount)")
                .foregroundStyle(Color.accentColor)
            Text("节课程")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .font(.system(size: 13, weight: .bold))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CourseRowView: View {
    let courseInfo: CourseOccurrence
    let isCurrent: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        let course = courseInfo.course
        let session = courseInfo.session

        Button(action: onTap) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 4)

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(course.courseName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if isCurrent {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        HStack(spacing: 6) {
                            Text(session.classroom ?? "未安排教室")
                                .lineLimit(1)

                            if let teacher = course.teacher, !teacher.isEmpty {
                                Text(teacher)
                                    .lineLimit(1)
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 2)

                    if let times = CourseSchedulePresentation.sectionTimes(for: session) {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(times.start)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(times.end)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .padding(.trailing, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyCourseContentView: View {
    var text: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
