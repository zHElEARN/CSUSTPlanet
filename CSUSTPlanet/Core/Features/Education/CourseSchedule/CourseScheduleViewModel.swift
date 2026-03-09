//
//  CourseScheduleViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/18.
//

import CSUSTKit
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
    var isExporting: Bool = false
    var isShowingSuccess: Bool = false
    var successMessage: String = ""

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

    func addToCalendar() {
        guard let data = self.data?.value else {
            self.errorMessage = "课表数据未加载，无法导出"
            self.isShowingError = true
            return
        }

        isExporting = true
        Task {
            defer {
                isExporting = false
            }
            do {
                let currentCalendar = Calendar.current

                let calendar = try await CalendarUtil.getOrCreateEventCalendar(named: "长理星球 - 课表")
                let clearStartDate = currentCalendar.date(byAdding: .year, value: -4, to: Date())!
                let clearEndDate = currentCalendar.date(byAdding: .year, value: 4, to: Date())!
                try await CalendarUtil.clearCalendar(calendar: calendar, from: clearStartDate, to: clearEndDate)

                for course in data.courses {
                    for session in course.sessions {
                        for week in session.weeks {
                            let datesOfWeek = CourseScheduleUtil.getDatesForWeek(semesterStartDate: data.semesterStartDate, week: week)
                            let targetDateIndex = session.dayOfWeek.rawValue
                            guard targetDateIndex < datesOfWeek.count else { continue }
                            // 通过这一周的每一天的时间和这一节课在周几，定位到当前课程课时的具体日期
                            let targetDate = datesOfWeek[targetDateIndex]

                            // 找到这节课在这一天的具体时间
                            let startSectionIndex = session.startSection - 1
                            let endSectionIndex = session.endSection - 1
                            guard startSectionIndex >= 0, startSectionIndex < CourseScheduleUtil.sectionTimeString.count,
                                endSectionIndex >= 0, endSectionIndex < CourseScheduleUtil.sectionTimeString.count
                            else {
                                continue
                            }
                            let startTimeString = CourseScheduleUtil.sectionTimeString[startSectionIndex].0
                            let endTimeString = CourseScheduleUtil.sectionTimeString[endSectionIndex].1
                            let startComponents = startTimeString.split(separator: ":").compactMap { Int($0) }
                            let endComponents = endTimeString.split(separator: ":").compactMap { Int($0) }
                            guard startComponents.count == 2, endComponents.count == 2,
                                let eventStartDate = currentCalendar.date(bySettingHour: startComponents[0], minute: startComponents[1], second: 0, of: targetDate),
                                let eventEndDate = currentCalendar.date(bySettingHour: endComponents[0], minute: endComponents[1], second: 0, of: targetDate)
                            else {
                                continue
                            }

                            // 与课程相关的备注信息
                            var notes = "教师: \(course.teacher ?? "未知")"
                            if let groupName = course.groupName { notes += "\n组名: \(groupName)" }
                            notes += "\n周次: 第\(week)周"

                            try await CalendarUtil.addEvent(
                                calendar: calendar,
                                title: course.courseName,
                                startDate: eventStartDate,
                                endDate: eventEndDate,
                                notes: notes,
                                location: session.classroom,
                                // 这里连续提交会有性能问题，所以这里不提交改变
                                commit: false
                            )
                        }
                    }
                }
                // 最后统一提交改变
                try CalendarUtil.commitChanges()

                isShowingSuccess = true
                successMessage = "已添加到日历"
            } catch {
                self.errorMessage = "导出失败: \(error.localizedDescription)"
                self.isShowingError = true
            }
        }
    }
}
