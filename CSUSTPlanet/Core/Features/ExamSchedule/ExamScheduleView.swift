//
//  ExamScheduleView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import CSUSTKit
import SwiftUI

struct ExamScheduleView: View {
    @State private var examData: Cached<[EduHelper.Exam]>? = MMKVHelper.ExamSchedule.cache

    @State private var availableSemesters: [String] = []

    @State private var isLoadingExams: Bool = false
    @State private var isLoadingSemesters: Bool = false

    @State private var selectedSemester: String?
    @State private var selectedSemesterType: EduHelper.SemesterType?

    @State private var errorToast: ToastState = .errorTitle
    @State private var successToast: ToastState = .successTitle
    @State private var loadingToast: ToastState = .init(title: "添加中")

    @State private var isInitial: Bool = true

    // MARK: - Body

    var body: some View {
        ExamScheduleContent(
            examData: examData,
            availableSemesters: availableSemesters,
            selectedSemester: $selectedSemester,
            selectedSemesterType: $selectedSemesterType,
            isLoadingExams: isLoadingExams,
            isLoadingSemesters: isLoadingSemesters,
            errorToast: $errorToast,
            successToast: $successToast,
            loadingToast: $loadingToast,
            onQuery: loadExams,
            onRefreshSemesters: loadAvailableSemesters,
            onApplyFilter: loadExams,
            onAddToCalendar: addToCalendar
        )
        .onReceive(MMKVHelper.ExamSchedule.$cache.dropFirst().receive(on: RunLoop.main)) { cachedData in
            examData = cachedData
        }
        .task {
            guard isInitial else { return }
            isInitial = false
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadAvailableSemesters() }
                group.addTask { await self.loadExams() }
            }
        }
    }

    // MARK: - Methods

    private func loadAvailableSemesters() async {
        guard !isLoadingSemesters else { return }
        isLoadingSemesters = true
        defer { isLoadingSemesters = false }

        do {
            (availableSemesters, selectedSemester) = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.examService.getAvailableSemestersForExamSchedule()
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func loadExams() async {
        guard !isLoadingExams else { return }
        isLoadingExams = true
        defer { isLoadingExams = false }

        do {
            let exams = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.examService.getExamSchedule(academicYearSemester: self.selectedSemester, semesterType: self.selectedSemesterType)
            }
            let sortedExams = exams.sorted {
                return $0.examStartTime < $1.examStartTime
            }

            let data = Cached<[EduHelper.Exam]>(cachedAt: .now, value: sortedExams)
            MMKVHelper.ExamSchedule.cache = data
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func addToCalendar() async {
        guard let exams = examData?.value, !exams.isEmpty else {
            errorToast.show(message: "考试安排为空，无法添加到日历")
            return
        }
        loadingToast.show(message: "正在添加到日历...")
        defer { loadingToast.hide() }
        do {
            let calendar = try await CalendarUtil.getOrCreateEventCalendar(suffix: "考试")
            for exam in exams {
                try await CalendarUtil.addEvent(
                    calendar: calendar,
                    title: "考试：\(exam.courseName)",
                    startDate: exam.examStartTime,
                    endDate: exam.examEndTime,
                    notes: "课程老师：\(exam.teacher)",
                    location: exam.examRoom
                )
            }
            successToast.show(message: "全部添加到日历成功")
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}

extension MMKVHelper {
    enum ExamSchedule {
        @MMKVOptionalStorage(key: "Cached.examSchedulesCache")
        static var cache: Cached<[EduHelper.Exam]>?
    }
}
