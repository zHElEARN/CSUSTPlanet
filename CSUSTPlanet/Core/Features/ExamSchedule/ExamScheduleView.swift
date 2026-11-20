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
                try await AuthManager.shared.eduHelper.getAvailableSemestersForExamSchedule()
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
                try await AuthManager.shared.eduHelper.getExamSchedule(academicYearSemester: self.selectedSemester, semesterType: self.selectedSemesterType)
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

    private func addToCalendar(accountID: String) async throws {
        guard let exams = examData?.value, !exams.isEmpty else {
            throw CalendarUtilError.noEventsToExport
        }

        let drafts = exams.map { exam in
            CalendarEventDraft(
                title: "考试：\(exam.courseName)",
                startDate: exam.examStartTime,
                endDate: exam.examEndTime,
                notes: "课程老师：\(exam.teacher)",
                location: exam.examRoom,
                timeZone: nil,
                alarmRelativeOffsets: []
            )
        }
        try await CalendarUtil.shared.addEvents(drafts, suffix: "考试", accountID: accountID)
        successToast.show(message: "全部添加到日历成功")
    }
}

extension MMKVHelper {
    enum ExamSchedule {
        @MMKVOptionalStorage(key: "Cached.examSchedulesCache")
        static var cache: Cached<[EduHelper.Exam]>?
    }
}
