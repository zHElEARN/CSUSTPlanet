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
import WidgetKit

@MainActor
@Observable
class CourseScheduleViewModel {
    var data: Cached<CourseScheduleData>? = nil
    var errorMessage: String = ""
    var warningMessage: String = ""
    var availableSemesters: [String] = []

    var isLoading: Bool = false
    var isShowingWarning: Bool = false
    var isShowingError: Bool = false
    var isSemestersLoading: Bool = false
    var isShowingSemestersSheet: Bool = false

    // 导出日历相关状态
    var isShowingAddToCalendarAlert: Bool = false
    var isAddToCalendarExporting: Bool = false
    var isShowingAddToCalendarSuccess: Bool = false

    // TabView显示的第几周
    var currentWeek: Int = 1
    var selectedSemester: String? = nil

    var selectedCourse: EduHelper.Course?
    var selectedSession: EduHelper.ScheduleSession?
    var isShowingDetail: Bool = false

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

    var isLoaded = false

    init() {
        guard let data = MMKVHelper.shared.courseScheduleCache else { return }
        self.data = data
        updateSchedules(data.value.semesterStartDate, data.value.courses)
    }

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadAvailableSemesters()
        loadCourses()
    }

    func loadAvailableSemesters() {
        guard let eduHelper = AuthManager.shared.eduHelper else { return }
        isSemestersLoading = true
        Task {
            defer {
                isSemestersLoading = false
            }

            do {
                (availableSemesters, selectedSemester) = try await eduHelper.courseService.getAvailableSemestersForCourseSchedule()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
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

    func loadCourses() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courses = try await eduHelper.courseService.getCourseSchedule(academicYearSemester: selectedSemester)
                    let semesterStartDate = try await eduHelper.semesterService.getSemesterStartDate(academicYearSemester: selectedSemester)
                    let data = Cached<CourseScheduleData>(cachedAt: .now, value: CourseScheduleData(semester: selectedSemester, semesterStartDate: semesterStartDate, courses: courses))
                    self.data = data
                    MMKVHelper.shared.courseScheduleCache = data
                    updateSchedules(semesterStartDate, courses)
                    WidgetCenter.shared.reloadTimelines(ofKind: "TodayCoursesWidget")
                    WidgetCenter.shared.reloadTimelines(ofKind: "WeeklyCoursesWidget")
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVHelper.shared.courseScheduleCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录教务系统后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                updateSchedules(data.value.semesterStartDate, data.value.courses)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
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

    func addToCalendar(
        firstReminderOffset: TimeInterval, isFirstEnabled: Bool,
        secondReminderOffset: TimeInterval, isSecondEnabled: Bool
    ) {
        guard let data = self.data?.value else {
            self.errorMessage = "课表数据未加载，无法导出"
            self.isShowingError = true
            return
        }

        isAddToCalendarExporting = true
        Task {
            defer {
                isAddToCalendarExporting = false
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

                            // 与课程相关的备注信息
                            var notes = "教师: \(course.teacher ?? "未知")"
                            if let groupName = course.groupName { notes += "\n组名: \(groupName)" }
                            notes += "\n周次: 第\(week)周"

                            var eventAlarms: [EKAlarm] = []
                            if isFirstEnabled {
                                eventAlarms.append(EKAlarm(relativeOffset: -firstReminderOffset))
                            }
                            if isSecondEnabled {
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

                isShowingAddToCalendarSuccess = true
            } catch {
                self.errorMessage = "导出失败: \(error.localizedDescription)"
                self.isShowingError = true
            }
        }
    }
}
