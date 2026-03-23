//
//  CourseDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/23.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
class CourseDetailViewModel {
    var assignments: [MoocHelper.Assignment] = []
    var exams: [MoocHelper.Exam] = []

    var isShowingAllAssignments = false

    var errorToast: ToastState = .errorTitle
    var successToast: ToastState = .successTitle

    var isLoadingAssignments = false
    var isLoadingExams = false

    var isRemindersSettingsPresented = false

    var isInitial = true

    var displayedAssignments: [MoocHelper.Assignment] {
        if isShowingAllAssignments {
            return assignments
        }

        let referenceDate = Date.now
        return assignments.filter { $0.deadline >= referenceDate }
    }

    func loadInitial(course: MoocHelper.Course) async {
        guard isInitial else { return }
        isInitial = false
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAssignments(course: course) }
            group.addTask { await self.loadExams(course: course) }
        }
    }

    func loadAssignments(course: MoocHelper.Course) async {
        guard !isLoadingAssignments else { return }
        isLoadingAssignments = true
        defer { isLoadingAssignments = false }

        do {
            assignments = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCourseAssignments(course: course)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadExams(course: MoocHelper.Course) async {
        guard !isLoadingExams else { return }
        isLoadingExams = true
        defer { isLoadingExams = false }

        do {
            exams = try await AuthManager.shared.withAuthRetry(system: .mooc) {
                try await AuthManager.shared.moocHelper.getCourseExams(course: course)
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    var dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter
    }()

    func addAssignmentsToReminders(_ alertHourOffset: Int, _ alertMinuteOffset: Int) async {
        guard !assignments.isEmpty else {
            errorToast.show(message: "当前没有可添加的作业")
            return
        }

        do {
            let calendar = try await CalendarUtil.getOrCreateReminderCalendar(named: "长理星球 - 作业")
            for assignment in assignments {
                guard assignment.canSubmit else { continue }
                let dueDate = assignment.deadline
                let alarmOffset = TimeInterval(-(alertHourOffset * 3600 + alertMinuteOffset * 60))
                let dueDateWithAlarm = dueDate.addingTimeInterval(alarmOffset)
                try await CalendarUtil.addReminder(
                    calendar: calendar,
                    title: assignment.title,
                    dueDate: dueDateWithAlarm,
                    notes: "截止提交时间：\(dateFormatter.string(from: assignment.deadline))\n课程老师：\(assignment.publisher)"
                )
            }
            successToast.show(message: "添加到提醒事项成功")
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
