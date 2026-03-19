//
//  ExamScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class ExamScheduleViewModel {
    var availableSemesters: [String] = []
    var examData: Cached<[EduHelper.Exam]>? = nil

    var isLoadingSemesters = false
    var isLoadingExams = false

    var isAddToCalendarAlertPresented = false
    var isFilterPresented: Bool = false
    var isShareSheetPresented: Bool = false

    var selectedSemester: String? = nil
    var selectedSemesterType: EduHelper.SemesterType? = nil

    var targetScrollID: String? = nil
    var now = Date()

    var refreshTrigger = false
    var semestersRefreshTrigger = false

    var errorToast = ToastState()
    var successToast = ToastState()

    init() {
        guard let data = MMKVHelper.shared.examSchedulesCache else { return }
        self.examData = data
        updateScrollTarget(exams: data.value)
    }

    func isExamFinished(_ exam: EduHelper.Exam) -> Bool {
        return now > exam.examEndTime
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }

    func loadInitial() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAvailableSemesters() }
            group.addTask { await self.loadExams() }
        }
    }

    func loadAvailableSemesters() async {
        isLoadingSemesters = true
        defer { isLoadingSemesters = false }

        do {
            (availableSemesters, selectedSemester) = try await AuthManager.shared.eduHelper.examService.getAvailableSemestersForExamSchedule()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func handleScrollOnAppear(proxy: ScrollViewProxy) {
        if let id = targetScrollID {
            DispatchQueue.main.async {
                withAnimation {
                    proxy.scrollTo(id, anchor: .top)
                }
            }
        }
    }

    func handleScrollOnChange(proxy: ScrollViewProxy, newID: String?) {
        if let id = newID {
            withAnimation {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }

    func addAllToCalendar() async {
        guard let exams = examData?.value else {
            errorToast.show(message: "考试安排为空，无法添加到日历")
            return
        }
        do {
            let calendar = try await CalendarUtil.getOrCreateEventCalendar(named: "长理星球 - 考试")
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

    private func updateScrollTarget(exams: [EduHelper.Exam]) {
        if let firstUnfinished = exams.first(where: { $0.examEndTime >= now }) {
            self.targetScrollID = firstUnfinished.courseID
        } else {
            self.targetScrollID = nil
        }
    }

    func loadExams() async {
        guard !isLoadingExams else { return }
        isLoadingExams = true
        defer { isLoadingExams = false }

        do {
            let exams = try await AuthManager.shared.eduHelper.examService.getExamSchedule(academicYearSemester: selectedSemester, semesterType: selectedSemesterType)
            let sortedExams = exams.sorted {
                return $0.examStartTime < $1.examStartTime
            }

            let data = Cached<[EduHelper.Exam]>(cachedAt: .now, value: sortedExams)
            self.examData = data
            self.updateScrollTarget(exams: sortedExams)
            MMKVHelper.shared.examSchedulesCache = data
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
