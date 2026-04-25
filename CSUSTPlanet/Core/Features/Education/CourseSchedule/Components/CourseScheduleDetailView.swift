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
    let showsCustomizationActions: Bool
    let isCustomCourse: Bool
    let onHideOfficialCourse: () -> Void
    let onEditCustomCourse: () -> Void
    let onDeleteCustomCourse: () -> Void
    @Binding var isPresented: Bool

    @State private var isHideConfirmationPresented = false
    @State private var isDeleteConfirmationPresented = false

    init(
        course: EduHelper.Course,
        session: EduHelper.ScheduleSession,
        isShowingToolbar: Bool,
        showsCustomizationActions: Bool = false,
        isCustomCourse: Bool = false,
        onHideOfficialCourse: @escaping () -> Void = {},
        onEditCustomCourse: @escaping () -> Void = {},
        onDeleteCustomCourse: @escaping () -> Void = {},
        isPresented: Binding<Bool>
    ) {
        self.course = course
        self.session = session
        self.isShowingToolbar = isShowingToolbar
        self.showsCustomizationActions = showsCustomizationActions
        self.isCustomCourse = isCustomCourse
        self.onHideOfficialCourse = onHideOfficialCourse
        self.onEditCustomCourse = onEditCustomCourse
        self.onDeleteCustomCourse = onDeleteCustomCourse
        self._isPresented = isPresented
    }

    private var otherSessions: [EduHelper.ScheduleSession] {
        course.sessions.filter { $0 != session }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 课程基本信息
                Section {
                    VStack(spacing: 8) {
                        Text(course.courseName)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        HStack(spacing: 12) {
                            if let teacher = course.teacher {
                                Label(teacher, systemImage: "person.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let groupName = course.groupName {
                                Text(groupName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // MARK: - 本次安排
                Section("本次安排") {
                    FormRow(label: "课程周次", value: formatWeeks(session.weeks))
                    FormRow(label: "上课时间", value: "\(session.dayOfWeek.chineseLongString) · 第\(session.startSection)-\(session.endSection)节")
                    FormRow(label: "上课教室", value: session.classroom ?? "未安排教室")
                }

                // MARK: - 其他安排
                if !otherSessions.isEmpty {
                    Section("其他安排") {
                        ForEach(otherSessions, id: \.self) { otherSession in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(otherSession.dayOfWeek.chineseLongString)
                                        .fontWeight(.medium)
                                    Text("第\(otherSession.startSection)-\(otherSession.endSection)节")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(otherSession.classroom ?? "未安排教室")
                                        .font(.subheadline)
                                        .foregroundStyle(otherSession.classroom == nil ? .secondary : .primary)
                                }

                                Text(formatWeeks(otherSession.weeks))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if showsCustomizationActions {
                    Section("操作") {
                        if isCustomCourse {
                            Button {
                                onEditCustomCourse()
                            } label: {
                                Label("编辑课程", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                isDeleteConfirmationPresented = true
                            } label: {
                                Label("删除课程", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive) {
                                isHideConfirmationPresented = true
                            } label: {
                                Label("隐藏此课程", systemImage: "eye.slash")
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("课程详情")
            .inlineToolbarTitle()
            .alert("隐藏课程", isPresented: $isHideConfirmationPresented) {
                Button("隐藏", role: .destructive) {
                    onHideOfficialCourse()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("隐藏后，这门官方课程的所有上课时间都会从课表中移除。")
            }
            .alert("删除课程", isPresented: $isDeleteConfirmationPresented) {
                Button("删除", role: .destructive) {
                    onDeleteCustomCourse()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后，这门自定义课程会从课表中移除。")
            }
            .apply { view in
                if isShowingToolbar {
                    view.toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                isPresented = false
                            }
                        }
                    }
                } else {
                    view
                }
            }
        }
    }
}

// MARK: - Helpers
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
                    result.append("第\(start)-\(prev)周")
                }
                start = week
                prev = week
            }
        }

        if start == prev {
            result.append("第\(start)周")
        } else {
            result.append("第\(start)-\(prev)周")
        }

        return result.joined(separator: ", ")
    }
}
