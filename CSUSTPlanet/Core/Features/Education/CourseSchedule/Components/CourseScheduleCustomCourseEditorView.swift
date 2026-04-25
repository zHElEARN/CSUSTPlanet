//
//  CourseScheduleCustomCourseEditorView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/4/25.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleCustomCourseEditorView: View {
    let viewModel: CourseScheduleViewModel
    let editingCourse: CourseScheduleCustomCourse?

    @Environment(\.dismiss) private var dismiss

    @State private var courseName: String
    @State private var groupName: String
    @State private var teacher: String
    @State private var classroom: String
    @State private var selectedDayOfWeek: EduHelper.DayOfWeek
    @State private var startSection: Int
    @State private var endSection: Int
    @State private var selectedWeeks: Set<Int>

    private var isEditing: Bool { editingCourse != nil }

    init(viewModel: CourseScheduleViewModel, editingCourse: CourseScheduleCustomCourse?) {
        self.viewModel = viewModel
        self.editingCourse = editingCourse

        let course = editingCourse?.course
        let session = course?.sessions.first

        _courseName = State(initialValue: course?.courseName ?? "")
        _groupName = State(initialValue: course?.groupName ?? "")
        _teacher = State(initialValue: course?.teacher ?? "")
        _classroom = State(initialValue: session?.classroom ?? "")
        _selectedDayOfWeek = State(initialValue: session?.dayOfWeek ?? .monday)
        _startSection = State(initialValue: session?.startSection ?? 1)
        _endSection = State(initialValue: session?.endSection ?? 2)
        _selectedWeeks = State(initialValue: Set(session?.weeks ?? [viewModel.currentWeek]))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("课程信息") {
                    TextField("课程名称", text: $courseName)
                    TextField("授课教师", text: $teacher)
                    TextField("分组名称", text: $groupName)
                    TextField("上课教室", text: $classroom)
                }

                Section("上课时间") {
                    Picker("星期", selection: $selectedDayOfWeek) {
                        ForEach(EduHelper.DayOfWeek.allCases, id: \.self) { day in
                            Text(day.chineseLongString).tag(day)
                        }
                    }

                    Picker("开始节次", selection: $startSection) {
                        ForEach(1...10, id: \.self) { section in
                            Text("第 \(section) 节").tag(section)
                        }
                    }
                    .onChange(of: startSection) { _, newValue in
                        if endSection < newValue {
                            endSection = newValue
                        }
                    }

                    Picker("结束节次", selection: $endSection) {
                        ForEach(startSection...10, id: \.self) { section in
                            Text("第 \(section) 节").tag(section)
                        }
                    }
                }

                Section("上课周次") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(1...CourseScheduleUtil.weekCount, id: \.self) { week in
                            Button {
                                toggleWeek(week)
                            } label: {
                                Text("\(week)")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(selectedWeeks.contains(week) ? Color.accentColor : Color.secondary.opacity(0.35))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "编辑课程" : "添加课程")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("保存") {
                        viewModel.saveCustomCourse(makeCourse(), editingID: editingCourse?.id)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedWeeks.isEmpty
            && startSection <= endSection
    }

    private func toggleWeek(_ week: Int) {
        if selectedWeeks.contains(week) {
            selectedWeeks.remove(week)
        } else {
            selectedWeeks.insert(week)
        }
    }

    private func makeCourse() -> EduHelper.Course {
        let session = EduHelper.ScheduleSession(
            weeks: selectedWeeks.sorted(),
            startSection: startSection,
            endSection: endSection,
            dayOfWeek: selectedDayOfWeek,
            classroom: normalizedOptional(classroom)
        )

        return EduHelper.Course(
            courseName: courseName.trimmingCharacters(in: .whitespacesAndNewlines),
            groupName: normalizedOptional(groupName),
            teacher: normalizedOptional(teacher),
            sessions: [session]
        )
    }

    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
