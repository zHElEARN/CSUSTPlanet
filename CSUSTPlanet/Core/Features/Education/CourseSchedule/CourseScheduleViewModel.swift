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
class CourseScheduleViewModel: ObservableObject {
    @Published var data: Cached<CourseScheduleData>? = nil
    @Published var errorMessage: String = ""
    @Published var warningMessage: String = ""
    @Published var availableSemesters: [String] = []

    @Published var isLoading: Bool = false
    @Published var isShowingWarning: Bool = false
    @Published var isShowingError: Bool = false
    @Published var isSemestersLoading: Bool = false
    @Published var isShowingSemestersSheet: Bool = false

    // 导出日历相关状态
    @Published var isShowingAddToCalendarAlert: Bool = false
    @Published var isExporting: Bool = false
    @Published var isShowingSuccess: Bool = false
    @Published var successMessage: String = ""

    // TabView显示的第几周
    @Published var currentWeek: Int = 1
    @Published var selectedSemester: String? = nil

    @Published var selectedCourse: EduHelper.Course?
    @Published var selectedSession: EduHelper.ScheduleSession?
    @Published var isShowingDetail: Bool = false

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
    @Published var realCurrentWeek: Int? = nil

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
                try await CalendarUtil.addCoursesToCalendar(courses: data.courses, semesterStartDate: data.semesterStartDate)

                // 成功后提醒用户
                isShowingSuccess = true
                successMessage = "已添加到日历"
            } catch {
                self.errorMessage = "导出失败: \(error.localizedDescription)"
                self.isShowingError = true
            }
        }
    }
}
