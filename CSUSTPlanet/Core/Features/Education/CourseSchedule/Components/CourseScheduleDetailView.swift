//
//  CourseScheduleDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleDetailView: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let isShowingToolbar: Bool
    @Binding var isPresented: Bool

    private var otherSessions: [EduHelper.ScheduleSession] {
        course.sessions.filter { $0 != session }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    currentSessionCard
                    if !otherSessions.isEmpty {
                        otherSessionsCard
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Color.appSystemGroupedBackground.ignoresSafeArea())
            .navigationTitle("课程详情")
            .inlineToolbarTitle()
            .apply { view in
                if isShowingToolbar {
                    view.toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                isPresented = false
                            } label: {
                                Text("关闭")
                            }
                        }
                    }
                } else {
                    view
                }
            }
        }
        .trackView("CourseScheduleDetail")
    }
}

// MARK: - Subviews
extension CourseScheduleDetailView {
    private var headerCard: some View {
        VStack(spacing: 12) {
            Text(course.courseName)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                if let teacher = course.teacher {
                    Label(teacher, systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let groupName = course.groupName {
                    Text(groupName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal)
        .background(Color.appSecondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var currentSessionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.accentColor)
                Text("本次安排")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            VStack(spacing: 16) {
                ScheduleInfoRow(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "课程周次",
                    value: formatWeeks(session.weeks)
                )

                Divider().padding(.leading, 36)

                ScheduleInfoRow(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: "上课时间",
                    value: "\(session.dayOfWeek.chineseLongString) · 第\(session.startSection)-\(session.endSection)节"
                )

                Divider().padding(.leading, 36)

                ScheduleInfoRow(
                    icon: "mappin.and.ellipse",
                    iconColor: .green,
                    title: "上课教室",
                    value: session.classroom ?? "未安排教室"
                )
            }
        }
        .padding()
        .background(Color.appSecondarySystemGroupedBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }

    private var otherSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("该课程的其他安排")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(otherSessions.enumerated()), id: \.element) { index, otherSession in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(otherSession.dayOfWeek.chineseLongString)
                                .fontWeight(.medium)
                            Text("第\(otherSession.startSection)-\(otherSession.endSection)节")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(otherSession.classroom ?? "无教室")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        Text(formatWeeks(otherSession.weeks))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()

                    if index < otherSessions.count - 1 {
                        Divider().padding(.leading)
                    }
                }
            }
            .background(Color.appSecondarySystemGroupedBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
    }
}

extension CourseScheduleDetailView {
    private func formatWeeks(_ weeks: [Int]) -> String {
        guard !weeks.isEmpty else { return "" }

        var result = [String]()
        var start = weeks[0]
        var prev = weeks[0]

        for week in weeks.dropFirst() {
            if week == prev + 1 {
                prev = week
            } else {
                if start == prev {
                    result.append("第\(start)周")
                } else {
                    result.append("第\(start)周-\(prev)周")
                }
                start = week
                prev = week
            }
        }

        if start == prev {
            result.append("第\(start)周")
        } else {
            result.append("第\(start)周-\(prev)周")
        }

        return result.joined(separator: ", ")
    }
}

private struct ScheduleInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Rectangle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
    }
}
