//
//  CourseOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct CourseOverviewView: View {
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(
                title: "今日课程",
                icon: "book.fill",
                color: .purple,
                destination: CourseScheduleView()
            )
            .padding(.horizontal)

            switch viewModel.courseDisplayState {
            case .loading:
                EmptyCourseCard(text: "暂无课程数据", icon: "cloud.sun.fill")
                    .padding(.horizontal)
                    .padding(.bottom, 10)

            case .beforeSemester(let days):
                if let days = days {
                    if days > CourseScheduleUtil.semesterStartThreshold {
                        EmptyCourseCard(
                            text: CourseScheduleUtil.getHolidayMessage(for: Date()),
                            subtitle: "学期未开始",
                            icon: "party.popper.fill"
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    } else {
                        EmptyCourseCard(
                            text: "学期未开始",
                            subtitle: "距离开学还有 \(days) 天",
                            icon: "calendar.badge.clock"
                        )
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                } else {
                    EmptyCourseCard(text: "学期未开始", icon: "calendar")
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }

            case .afterSemester:
                EmptyCourseCard(text: "本学期已结束，祝你假期愉快！", icon: "case.fill")
                    .padding(.horizontal)
                    .padding(.bottom, 10)

            case .inSemester(let courses):
                if !courses.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(courses.enumerated()), id: \.offset) { _, item in
                                CourseCard(
                                    course: item.course.course,
                                    session: item.course.session,
                                    isCurrent: item.isCurrent,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                } else {
                    EmptyCourseCard(text: "今天没有课，好好休息吧 ~", icon: "checkmark.circle.fill")
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            }
        }
    }
}

struct CourseCard: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let isCurrent: Bool
    @ObservedObject var viewModel: OverviewViewModel

    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.courseName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .foregroundStyle(.white)

                    if let teacher = course.teacher {
                        Text(teacher)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                Spacer()

                if isCurrent {
                    Text("进行中")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white)
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
            Spacer()
            HStack {
                Label(session.classroom ?? "未知地点", systemImage: "location.fill")
                Spacer()
                Text(viewModel.formatCourseTime(session.startSection, session.endSection))
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .frame(width: 240, height: 140)
        .background(
            LinearGradient(
                colors: isCurrent ? [.blue, .purple] : [.blue.opacity(0.8), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: isCurrent ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            CourseScheduleDetailView(course: course, session: session, isPresented: $showDetail)
        }
    }
}

struct EmptyCourseCard: View {
    var text: String = "今天没有课，好好休息吧 ~"
    var subtitle: String? = nil
    var icon: String = "cup.and.saucer.fill"

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 8)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
