//
//  CourseOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct CourseOverviewView: View {
    @State private var viewModel = CourseOverviewViewModel()
    @Environment(Router.self) private var router

    var body: some View {
        Button(action: { router.deepLinkTo(feature: .courseSchedule) }) {
            CustomGroupBox {
                cardContent
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(CourseScheduleUtil.courseScheduleTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Text(viewModel.semesterInfoText)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }

            contentView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.courseDisplayState {
        case .loading:
            EmptyCourseContentView(text: CourseScheduleUtil.emptyCourseScheduleText, icon: "cloud.sun.fill")

        case .beforeSemester(let days):
            if let days {
                if days > CourseScheduleUtil.semesterStartThreshold {
                    EmptyCourseContentView(
                        text: CourseScheduleUtil.getHolidayMessage(for: Date()),
                        subtitle: CourseScheduleUtil.semesterNotStartedText,
                        icon: "party.popper.fill"
                    )
                } else {
                    EmptyCourseContentView(
                        text: CourseScheduleUtil.semesterNotStartedText,
                        subtitle: CourseScheduleUtil.getSemesterCountdownText(days: days),
                        icon: "calendar.badge.clock"
                    )
                }
            } else {
                EmptyCourseContentView(text: CourseScheduleUtil.semesterNotStartedText, icon: "calendar")
            }

        case .afterSemester:
            EmptyCourseContentView(text: CourseScheduleUtil.semesterEndedText, icon: "case.fill")

        case .inSemester(let courses):
            if courses.isEmpty {
                EmptyCourseContentView(
                    text: CourseScheduleUtil.noCoursesTodayText,
                    icon: "checkmark.circle.fill",
                    iconColor: .green
                )
            } else {
                CourseListView(
                    courses: courses
                )
            }
        }
    }
}

private struct CourseListView: View {
    let courses: [(course: CourseDisplayInfo, isCurrent: Bool)]

    private var courseColors: [String: Color] {
        ColorUtil.getCourseColors(courses.map { $0.course.course })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(courses.enumerated()), id: \.offset) { _, item in
                CourseRowView(
                    course: item.course.course,
                    session: item.course.session,
                    isCurrent: item.isCurrent,
                    accentColor: courseColors[item.course.course.courseName] ?? .blue,
                    startSection: item.course.session.startSection,
                    endSection: item.course.session.endSection
                )
            }
        }
    }
}

private struct CourseRowView: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let isCurrent: Bool
    let accentColor: Color
    let startSection: Int
    let endSection: Int

    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
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
                            // .frame(maxWidth: .infinity, alignment: .leading)

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

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(CourseScheduleUtil.sectionTimeString[startSection - 1].0)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(CourseScheduleUtil.sectionTimeString[endSection - 1].1)
                            .font(.system(size: 14))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.trailing, 2)
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
        .sheet(isPresented: $showDetail) {
            CourseScheduleDetailView(
                course: course,
                session: session,
                isShowingToolbar: true,
                isPresented: $showDetail
            )
        }
    }
}

private struct EmptyCourseContentView: View {
    var text: String
    var subtitle: String? = nil
    var icon: String
    var iconColor: Color = .secondary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
