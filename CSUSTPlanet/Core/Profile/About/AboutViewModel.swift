//
//  AboutViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import Foundation

#if DEBUG
    import FLEX
#endif

@MainActor
final class AboutViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var aboutMarkdown: String?

    // MARK: - Computed Properties

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "未知版本"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "未知构建"
    }

    var environment: String {
        EnvironmentUtil.environment.rawValue
    }

    // MARK: - Initialization

    init() {
        loadAboutMarkdown()
    }

    // MARK: - Methods

    func loadAboutMarkdown() {
        aboutMarkdown = AssetUtil.loadMarkdownFile(named: "About")
    }

    // MARK: - Debug Methods

    #if DEBUG
        func generateMockData() {
            let today = Date()
            let calendar = Calendar.current

            // 获取今天是星期几
            let todayDayOfWeek = CourseScheduleUtil.getDayOfWeek(today)

            // 1. 生成今天的5节课
            let mockCourses = [
                EduHelper.Course(
                    courseName: "高等数学",
                    groupName: nil,
                    teacher: "张教授",
                    sessions: [
                        EduHelper.ScheduleSession(
                            weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
                            startSection: 1,
                            endSection: 2,
                            dayOfWeek: todayDayOfWeek,
                            classroom: "金12-101"
                        )
                    ]
                ),
                EduHelper.Course(
                    courseName: "大学英语",
                    groupName: nil,
                    teacher: "李老师",
                    sessions: [
                        EduHelper.ScheduleSession(
                            weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
                            startSection: 3,
                            endSection: 4,
                            dayOfWeek: todayDayOfWeek,
                            classroom: "金12-202"
                        )
                    ]
                ),
                EduHelper.Course(
                    courseName: "数据结构",
                    groupName: nil,
                    teacher: "王副教授",
                    sessions: [
                        EduHelper.ScheduleSession(
                            weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
                            startSection: 5,
                            endSection: 6,
                            dayOfWeek: todayDayOfWeek,
                            classroom: "金13-305"
                        )
                    ]
                ),
                EduHelper.Course(
                    courseName: "操作系统",
                    groupName: nil,
                    teacher: "刘教授",
                    sessions: [
                        EduHelper.ScheduleSession(
                            weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
                            startSection: 7,
                            endSection: 8,
                            dayOfWeek: todayDayOfWeek,
                            classroom: "金12-108"
                        )
                    ]
                ),
                EduHelper.Course(
                    courseName: "计算机网络",
                    groupName: nil,
                    teacher: "陈副教授",
                    sessions: [
                        EduHelper.ScheduleSession(
                            weeks: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
                            startSection: 9,
                            endSection: 10,
                            dayOfWeek: todayDayOfWeek,
                            classroom: "金6-201"
                        )
                    ]
                ),
            ]

            // 保存课表数据
            let courseScheduleData = CourseScheduleData(
                semester: "2025-2026学年第二学期",
                semesterStartDate: calendar.date(byAdding: .day, value: -14, to: today)!,
                courses: mockCourses
            )
            MMKVHelper.shared.courseScheduleCache = Cached(cachedAt: today, value: courseScheduleData)

            // 2. 生成4个待提交作业
            let mockAssignments = UrgentCoursesData(courses: [
                UrgentCoursesData.Course(name: "高等数学作业 - 第三章习题", id: "1"),
                UrgentCoursesData.Course(name: "数据结构课程设计", id: "2"),
                UrgentCoursesData.Course(name: "大学英语阅读理解作业", id: "3"),
                UrgentCoursesData.Course(name: "操作系统实验报告", id: "4"),
            ])
            MMKVHelper.shared.urgentCoursesCache = Cached(cachedAt: today, value: mockAssignments)

            // 3. 生成4个考试安排（时间都在今天之后）
            let mockExams = [
                EduHelper.Exam(
                    campus: "金盆岭校区",
                    session: "2025-2026-2",
                    courseID: "EXAM001",
                    courseName: "高等数学",
                    teacher: "张教授",
                    examTime: "2026-02-15 09:00-11:00",
                    examStartTime: calendar.date(byAdding: .day, value: 4, to: calendar.startOfDay(for: today))!.addingTimeInterval(9 * 3600),
                    examEndTime: calendar.date(byAdding: .day, value: 4, to: calendar.startOfDay(for: today))!.addingTimeInterval(11 * 3600),
                    examRoom: "金12-101",
                    seatNumber: "15",
                    admissionTicketNumber: "202401234567",
                    remarks: "请提前30分钟到达考场"
                ),
                EduHelper.Exam(
                    campus: "金盆岭校区",
                    session: "2025-2026-2",
                    courseID: "EXAM002",
                    courseName: "数据结构",
                    teacher: "王副教授",
                    examTime: "2026-02-18 14:00-16:00",
                    examStartTime: calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: today))!.addingTimeInterval(14 * 3600),
                    examEndTime: calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: today))!.addingTimeInterval(16 * 3600),
                    examRoom: "金13-305",
                    seatNumber: "28",
                    admissionTicketNumber: "202401234568",
                    remarks: "允许携带计算器"
                ),
                EduHelper.Exam(
                    campus: "金盆岭校区",
                    session: "2025-2026-2",
                    courseID: "EXAM003",
                    courseName: "操作系统",
                    teacher: "刘教授",
                    examTime: "2026-02-20 09:00-11:00",
                    examStartTime: calendar.date(byAdding: .day, value: 9, to: calendar.startOfDay(for: today))!.addingTimeInterval(9 * 3600),
                    examEndTime: calendar.date(byAdding: .day, value: 9, to: calendar.startOfDay(for: today))!.addingTimeInterval(11 * 3600),
                    examRoom: "金12-108",
                    seatNumber: "42",
                    admissionTicketNumber: "202401234569",
                    remarks: ""
                ),
                EduHelper.Exam(
                    campus: "金盆岭校区",
                    session: "2025-2026-2",
                    courseID: "EXAM004",
                    courseName: "计算机网络",
                    teacher: "陈副教授",
                    examTime: "2026-02-25 14:00-16:00",
                    examStartTime: calendar.date(byAdding: .day, value: 14, to: calendar.startOfDay(for: today))!.addingTimeInterval(14 * 3600),
                    examEndTime: calendar.date(byAdding: .day, value: 14, to: calendar.startOfDay(for: today))!.addingTimeInterval(16 * 3600),
                    examRoom: "金6-201",
                    seatNumber: "33",
                    admissionTicketNumber: "202401234570",
                    remarks: "闭卷考试"
                ),
            ]
            MMKVHelper.shared.examSchedulesCache = Cached(cachedAt: today, value: mockExams)
        }

        func clearAllSwiftData() {
            try? SharedModelUtil.clearAllData()
        }

        func clearAllMMKVData() {
            MMKVHelper.shared.clearAll()
        }

        func clearAllKeychainData() {
            KeychainUtil.deleteAll()
        }

        func showFlexExplorer() {
            FLEXManager.shared.showExplorer()
        }
    #endif
}
