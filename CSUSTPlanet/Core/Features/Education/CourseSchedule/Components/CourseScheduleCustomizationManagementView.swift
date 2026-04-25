//
//  CourseScheduleCustomizationManagementView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/4/25.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleCustomizationManagementView: View {
    let viewModel: CourseScheduleViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("自定义课程") {
                    if viewModel.currentCustomization.customCourses.isEmpty {
                        Text("暂无自定义课程")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.currentCustomization.customCourses) { customCourse in
                            customCourseRow(customCourse)
                        }
                    }
                }

                Section("已隐藏官方课程") {
                    let hiddenCourseNames = viewModel.currentCustomization.hiddenOfficialCourseNames.sorted()
                    if hiddenCourseNames.isEmpty {
                        Text("暂无隐藏课程")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(hiddenCourseNames, id: \.self) { courseName in
                            HStack {
                                Text(courseName)
                                Spacer()
                                Button("恢复") {
                                    viewModel.restoreOfficialCourse(named: courseName)
                                }
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("自定义管理")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func customCourseRow(_ customCourse: CourseScheduleCustomCourse) -> some View {
        let course = customCourse.course
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.courseName)
                        .font(.headline)

                    if let session = course.sessions.first {
                        Text("\(session.dayOfWeek.chineseLongString) · 第\(session.startSection)-\(session.endSection)节 · \(formatWeeks(session.weeks))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button("删除", role: .destructive) {
                    viewModel.deleteCustomCourse(customCourse)
                }
            }

            if let teacher = course.teacher {
                Label(teacher, systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatWeeks(_ weeks: [Int]) -> String {
        guard !weeks.isEmpty else { return "未选择周次" }
        return weeks.map { "\($0)" }.joined(separator: ",") + "周"
    }
}
