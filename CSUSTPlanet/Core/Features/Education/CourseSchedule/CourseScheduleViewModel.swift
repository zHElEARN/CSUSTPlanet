//
//  CourseScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
import EventKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class CourseScheduleViewModel {
    var courseScheduleData: Cached<CourseScheduleData>? = nil
    var availableSemesters: [String] = []

    var isCourseScheduleLoading: Bool = false
    var isSemestersLoading: Bool = false

    var isSemestersSheetPresented: Bool = false
    var isCalendarSettingsSheetPresented: Bool = false

    var isCourseDetailPresented: Bool = false

    // TabView显示的第几周
    var currentWeek: Int = 1
    var selectedSemester: String? = nil

    var selectedCourseInfo: CourseDisplayInfo?

    var courseColors: [String: Color] = [:]

    // 当日日期
    // #if DEBUG
    //     let today: Date = {
    //         let dateFormatter = DateFormatter()
    //         dateFormatter.dateFormat = "yyyy-MM-dd"
    //         // 调试时使用固定日期
    //         return dateFormatter.date(from: "2025-09-15")!
    //     }()
    // #else
    let today: Date = .now
    // #endif

    // 当前日期在第几周
    var realCurrentWeek: Int? = nil

    var errorToast: ToastState = .errorTitle
    var loadingToast: ToastState = .init(title: "添加中")
    var successToast: ToastState = .init(title: "添加成功")

    var isInitial: Bool = true

    init() {
        guard let data = MMKVHelper.shared.courseScheduleCache else { return }
        self.courseScheduleData = data
        updateSchedules(data.value.semesterStartDate, data.value.courses)
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadAvailableSemesters() }
            group.addTask { await self.loadCourses() }
        }
        // Task {
        //     syncCalendarIfNeeded()
        // }
    }

    func loadAvailableSemesters() async {
        guard !isSemestersLoading else { return }
        isSemestersLoading = true
        defer { isSemestersLoading = false }

        do {
            (availableSemesters, selectedSemester) = try await AuthManager.shared.eduHelper.courseService.getAvailableSemestersForCourseSchedule()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func loadCourses() async {
        guard !isCourseScheduleLoading else { return }
        isCourseScheduleLoading = true
        defer { isCourseScheduleLoading = false }

        do {
            let courses = try await AuthManager.shared.eduHelper.courseService.getCourseSchedule(academicYearSemester: selectedSemester)
            let semesterStartDate = try await AuthManager.shared.eduHelper.semesterService.getSemesterStartDate(academicYearSemester: selectedSemester)
            let data = Cached<CourseScheduleData>(cachedAt: .now, value: CourseScheduleData(semester: selectedSemester, semesterStartDate: semesterStartDate, courses: courses))
            self.courseScheduleData = data
            MMKVHelper.shared.courseScheduleCache = data
            updateSchedules(semesterStartDate, courses)
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func updateSchedules(_ semesterStartDate: Date, _ courses: [EduHelper.Course]) {
        self.realCurrentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: semesterStartDate, now: today)

        // 为每门课程分配颜色
        courseColors = ColorUtil.getCourseColors(courses)

        // 自动跳转到当前周
        if let week = realCurrentWeek {
            withAnimation {
                self.currentWeek = week
            }
        }
    }

    func goToCurrentWeek() {
        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= CourseScheduleUtil.weekCount {
            withAnimation {
                self.currentWeek = realWeek
            }
        } else {
            withAnimation {
                self.currentWeek = 1
            }
        }
    }

    func addToCalendar(firstReminderOffset: TimeInterval?, secondReminderOffset: TimeInterval?, scopeLimit: Int? = nil, isSilent: Bool = false) {
        guard let data = self.courseScheduleData?.value else {
            if !isSilent {
                errorToast.show(message: "课表数据未加载，无法导出")
            }
            return
        }

        if !isSilent {
            loadingToast.show(message: "正在将课表添加到日历")
        }
        Task {
            defer {
                if !isSilent {
                    loadingToast.hide()
                }
            }
            do {
                let currentCalendar = Calendar.current

                let calendar = try await CalendarUtil.getOrCreateEventCalendar(named: "长理星球 - 课表")
                let clearStartDate = currentCalendar.date(byAdding: .year, value: -1, to: Date())!
                let clearEndDate = currentCalendar.date(byAdding: .year, value: 1, to: Date())!
                try await CalendarUtil.clearCalendar(calendar: calendar, from: clearStartDate, to: clearEndDate)

                for course in data.courses {
                    for session in course.sessions {
                        for week in session.weeks {
                            guard let dates = CourseScheduleUtil.getCourseEventDates(session: session, week: week, semesterStartDate: data.semesterStartDate) else { continue }
                            let eventStartDate = dates.startDate
                            let eventEndDate = dates.endDate

                            if let expectedWeeks = scopeLimit {
                                let startOfToday = currentCalendar.startOfDay(for: Date())
                                let timeLimit = currentCalendar.date(byAdding: .day, value: expectedWeeks * 7, to: startOfToday)!
                                guard eventStartDate >= startOfToday && eventStartDate < timeLimit else {
                                    continue
                                }
                            }

                            // 与课程相关的备注信息
                            var notes = "教师: \(course.teacher ?? "未知")"
                            if let groupName = course.groupName { notes += "\n组名: \(groupName)" }
                            notes += "\n周次: 第\(week)周"

                            var eventAlarms: [EKAlarm] = []
                            if let firstReminderOffset = firstReminderOffset {
                                eventAlarms.append(EKAlarm(relativeOffset: -firstReminderOffset))
                            }
                            if let secondReminderOffset = secondReminderOffset {
                                eventAlarms.append(EKAlarm(relativeOffset: -secondReminderOffset))
                            }

                            try await CalendarUtil.addEvent(
                                calendar: calendar,
                                title: course.courseName,
                                startDate: eventStartDate,
                                endDate: eventEndDate,
                                notes: notes,
                                location: session.classroom,
                                alarms: eventAlarms.isEmpty ? nil : eventAlarms,
                                // 这里连续提交会有性能问题，所以这里不提交改变
                                commit: false,
                                skipDuplicateCheck: true
                            )
                        }
                    }
                }
                // 最后统一提交改变
                try CalendarUtil.commitChanges()

                if !isSilent {
                    successToast.show(message: "课表已成功添加到日历")
                }
                MMKVHelper.shared.calendarLastSyncDate = .now
            } catch {
                if !isSilent {
                    errorToast.show(message: "导出失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 如果用户设置了导出范围，则在每天进入 app 时自动同步一次日历
    func syncCalendarIfNeeded() {
        guard let scopeLimit = MMKVHelper.shared.calendarExportScopeLimit else { return }

        if let lastSync = MMKVHelper.shared.calendarLastSyncDate {
            // 如果上次同步是在今天，就不再同步
            if Calendar.current.isDateInToday(lastSync) {
                return
            }
        }

        // 只有在数据加载完成后才同步
        guard courseScheduleData != nil else { return }

        addToCalendar(
            firstReminderOffset: MMKVHelper.shared.calendarFirstReminderOffset,
            secondReminderOffset: MMKVHelper.shared.calendarSecondReminderOffset,
            scopeLimit: scopeLimit,
            isSilent: true
        )
    }
}
