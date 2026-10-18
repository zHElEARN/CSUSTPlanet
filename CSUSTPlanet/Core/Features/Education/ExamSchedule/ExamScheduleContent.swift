//
//  ExamScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import CSUSTKit
import SwiftUI

struct ExamScheduleContent: View {
    let examData: Cached<[EduHelper.Exam]>?

    let availableSemesters: [String]

    @Binding var selectedSemester: String?
    @Binding var selectedSemesterType: EduHelper.SemesterType?

    let isLoadingExams: Bool
    let isLoadingSemesters: Bool

    @Binding var errorToast: ToastState
    @Binding var successToast: ToastState
    @Binding var loadingToast: ToastState

    let onQuery: () async -> Void
    let onRefreshSemesters: () async -> Void
    let onApplyFilter: () async -> Void
    let onAddToCalendar: () async -> Void

    @State private var isFilterPresented: Bool = false
    @State private var isAddToCalendarAlertPresented: Bool = false

    private var exams: [EduHelper.Exam] {
        examData?.value ?? []
    }

    // MARK: - Body

    var body: some View {
        ListPageScaffold(
            title: "考试安排",
            subtitle: "共 \(exams.count) 门考试",
            isEmpty: exams.isEmpty,
            isLoading: isLoadingExams,
            emptyNoun: "考试安排",
            errorToast: $errorToast,
            successToast: $successToast,
            loadingToast: $loadingToast,
            onQuery: onQuery
        ) {
            ForEach(exams, id: \.courseID) { exam in
                examCard(exam: exam).id(exam.courseID)
            }
        }
        .sheet(isPresented: $isFilterPresented) { filterView.presentationDetents([.medium, .large]) }
        .alert("添加日历", isPresented: $isAddToCalendarAlertPresented) {
            Button(asyncAction: onAddToCalendar) {
                Text("确认添加")
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("是否将所有考试安排添加到系统日历？")
        }
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { isFilterPresented.toggle() }) {
                    Label("高级查询", systemImage: "slider.horizontal.3")
                }
                .disabled(isLoadingExams)

                Button(action: { isAddToCalendarAlertPresented = true }) {
                    Label("全部添加到日历", systemImage: "calendar.badge.plus")
                }
                .disabled(exams.isEmpty || isLoadingExams)
            }
        }
    }

    // MARK: - Exam Card

    @ViewBuilder
    private func examCard(exam: EduHelper.Exam) -> some View {
        let finished = isExamFinished(exam)
        let daysLeft = daysUntilExam(exam)
        let dateStyle = finished ? RelativeDateStyle.secondary : RelativeDateStyle.scheduled(for: exam.examStartTime)
        let statusText: String =
            if finished {
                "已结束"
            } else if daysLeft == 0 {
                "今天"
            } else if daysLeft == 1 {
                "明天"
            } else if daysLeft == 2 {
                "后天"
            } else {
                "还有 \(daysLeft) 天"
            }

        CustomGroupBox {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(exam.courseName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(finished ? .secondary : .primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    RelativeDateBadge(
                        text: statusText,
                        style: dateStyle,
                        font: .caption.bold()
                    )
                }
                .padding(.bottom, 12)

                Divider()
                    .padding(.bottom, 12)

                // Info Rows
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(icon: "clock.fill", color: .blue, text: exam.examTime, finished: finished)

                    HStack(spacing: 0) {
                        detailRow(icon: "building.columns.fill", color: .green, text: exam.examRoom, finished: finished)
                        Spacer()
                        if !exam.seatNumber.isEmpty {
                            detailRow(icon: "number.square.fill", color: .orange, text: "座号: \(exam.seatNumber)", finished: finished)
                        }
                    }

                    if !exam.teacher.isEmpty {
                        detailRow(icon: "person.fill", color: .purple, text: exam.teacher, finished: finished)
                    }

                    if !exam.admissionTicketNumber.isEmpty {
                        detailRow(icon: "doc.text.fill", color: .red, text: "准考证: \(exam.admissionTicketNumber)", finished: finished)
                    }

                    if !exam.remarks.isEmpty {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(finished ? .gray : .secondary)
                                .frame(width: 16)
                            Text(exam.remarks)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .opacity(finished ? 0.6 : 1.0)
        .saturation(finished ? 0.0 : 1.0)
    }

    // MARK: - Detail Row

    @ViewBuilder
    private func detailRow(icon: String, color: Color, text: String, finished: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(finished ? .gray : color)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundColor(finished ? .secondary : .primary)
                .lineLimit(1)
        }
    }

    // MARK: - Helpers

    private func isExamFinished(_ exam: EduHelper.Exam) -> Bool {
        return .now > exam.examEndTime
    }

    private func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }
}

extension ExamScheduleContent {
    // MARK: - Filter View

    @ViewBuilder
    private var filterView: some View {
        NavigationStack {
            Form {
                Section(header: Text("学期选择")) {
                    Picker("学期", selection: $selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #elseif os(macOS)
                    .pickerStyle(.menu)
                    #endif
                    HStack {
                        Button(asyncAction: onRefreshSemesters) {
                            Text("刷新学期列表")
                        }
                        if isLoadingSemesters {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }
                }
                Section(header: Text("筛选条件")) {
                    Picker("考试类型", selection: $selectedSemesterType) {
                        Text("全部类型").tag(nil as EduHelper.SemesterType?)
                        ForEach(EduHelper.SemesterType.allCases, id: \.self) { semesterType in
                            Text(semesterType.rawValue).tag(semesterType as EduHelper.SemesterType?)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("高级查询")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(asyncAction: {
                        isFilterPresented = false
                        await onApplyFilter()
                    }) {
                        Text("完成")
                    }
                }
            }
        }
    }
}

#Preview("Normal") {
    NavigationStack {
        ExamScheduleContent(
            examData: Cached(cachedAt: .now, value: ExamSchedulePreviewData.exams),
            availableSemesters: ["2025-2026-1", "2025-2026-2"],
            selectedSemester: .constant(nil),
            selectedSemesterType: .constant(nil),
            isLoadingExams: false,
            isLoadingSemesters: false,
            errorToast: .constant(.errorTitle),
            successToast: .constant(.successTitle),
            loadingToast: .constant(.init(title: "添加中")),
            onQuery: {},
            onRefreshSemesters: {},
            onApplyFilter: {},
            onAddToCalendar: {}
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        ExamScheduleContent(
            examData: nil,
            availableSemesters: [],
            selectedSemester: .constant(nil),
            selectedSemesterType: .constant(nil),
            isLoadingExams: false,
            isLoadingSemesters: false,
            errorToast: .constant(.errorTitle),
            successToast: .constant(.successTitle),
            loadingToast: .constant(.init(title: "添加中")),
            onQuery: {},
            onRefreshSemesters: {},
            onApplyFilter: {},
            onAddToCalendar: {}
        )
    }
}

// MARK: - Preview Data

private enum ExamSchedulePreviewData {
    static let exams: [EduHelper.Exam] = [
        makeExam(
            courseID: "MATH1001",
            courseName: "高等数学A(一)",
            teacher: "李老师",
            examTime: "2025-12-30 09:00-11:00",
            startTimeOffset: -1_728_000,
            examRoom: "云塘校区 综合教学楼 A101",
            seatNumber: "12",
            admissionTicketNumber: "20251230001",
            remarks: "已结束的考试样例"
        ),
        makeExam(
            courseID: "CS1001",
            courseName: "程序设计基础",
            teacher: "王老师",
            examTime: "2026-01-05 14:00-16:00",
            startTimeOffset: 259_200,
            examRoom: "云塘校区 综合教学楼 B203",
            seatNumber: "08",
            admissionTicketNumber: "20260105002",
            remarks: ""
        ),
        makeExam(
            courseID: "PHYS1001",
            courseName: "大学物理实验",
            teacher: "张老师",
            examTime: "2026-01-12 09:00-11:00",
            startTimeOffset: 864_000,
            examRoom: "金盆岭校区 电苑楼 301",
            seatNumber: "",
            admissionTicketNumber: "",
            remarks: "请携带学生证"
        ),
    ]

    private static func makeExam(
        courseID: String,
        courseName: String,
        teacher: String,
        examTime: String,
        startTimeOffset: TimeInterval,
        examRoom: String,
        seatNumber: String,
        admissionTicketNumber: String,
        remarks: String
    ) -> EduHelper.Exam {
        let startTime = Date.now.addingTimeInterval(startTimeOffset)
        return EduHelper.Exam(
            campus: "云塘校区",
            session: "第一场",
            courseID: courseID,
            courseName: courseName,
            teacher: teacher,
            examTime: examTime,
            examStartTime: startTime,
            examEndTime: startTime.addingTimeInterval(7200),
            examRoom: examRoom,
            seatNumber: seatNumber,
            admissionTicketNumber: admissionTicketNumber,
            remarks: remarks
        )
    }
}
