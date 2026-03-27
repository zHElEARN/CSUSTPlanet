//
//  MockDataGeneratorView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/27.
//

#if DEBUG
import CSUSTKit
import SwiftUI

struct MockDataGeneratorView: View {
    @State private var todoAssignmentsCacheDescription = ""
    @State private var examSchedulesCacheDescription = ""
    @State private var courseScheduleCacheDescription = ""

    var body: some View {
        Form {
            Section {
                Button("清空待提交作业数据（nil）") {
                    MMKVHelper.TodoAssignments.cache = nil
                    refreshTodoAssignmentsCacheDescription()
                }

                Button("清空待提交作业数据（空数组）") {
                    MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: [])
                    refreshTodoAssignmentsCacheDescription()
                }

                Button("生成两个模拟待提交作业") {
                    MMKVHelper.TodoAssignments.cache = Cached(
                        cachedAt: .now,
                        value: MockTodoAssignmentsFactory.makeTwoAssignmentsData()
                    )
                    refreshTodoAssignmentsCacheDescription()
                }
            } header: {
                Text("待提交作业")
            } footer: {
                Text(todoAssignmentsCacheDescription)
            }

            Section {
                Button("清空考试安排数据（nil）") {
                    MMKVHelper.shared.examSchedulesCache = nil
                    refreshExamSchedulesCacheDescription()
                }

                Button("清空考试安排数据（空数组）") {
                    MMKVHelper.shared.examSchedulesCache = Cached(cachedAt: .now, value: [])
                    refreshExamSchedulesCacheDescription()
                }

                Button("生成 5 条模拟考试安排") {
                    MMKVHelper.shared.examSchedulesCache = Cached(
                        cachedAt: .now,
                        value: MockExamSchedulesFactory.makeFiveExamsData()
                    )
                    refreshExamSchedulesCacheDescription()
                }
            } header: {
                Text("考试安排")
            } footer: {
                Text(examSchedulesCacheDescription)
            }

            Section {
                Button("清空课表数据（nil）") {
                    MMKVHelper.shared.courseScheduleCache = nil
                    refreshCourseScheduleCacheDescription()
                }

                Button("清空课表数据（空课程）") {
                    MMKVHelper.shared.courseScheduleCache = Cached(
                        cachedAt: .now,
                        value: MockCourseScheduleFactory.makeEmptyCourseScheduleData()
                    )
                    refreshCourseScheduleCacheDescription()
                }

                Button("生成今日满课模拟课表") {
                    MMKVHelper.shared.courseScheduleCache = Cached(
                        cachedAt: .now,
                        value: MockCourseScheduleFactory.makeTodayFilledCourseScheduleData()
                    )
                    refreshCourseScheduleCacheDescription()
                }
            } header: {
                Text("课表")
            } footer: {
                Text(courseScheduleCacheDescription)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("模拟数据生成")
        .onAppear {
            refreshTodoAssignmentsCacheDescription()
            refreshExamSchedulesCacheDescription()
            refreshCourseScheduleCacheDescription()
        }
    }

    private func refreshTodoAssignmentsCacheDescription() {
        guard let cache = MMKVHelper.TodoAssignments.cache else {
            todoAssignmentsCacheDescription = "当前状态：nil"
            return
        }

        let assignmentCount = cache.value.reduce(into: 0) { partialResult, item in
            partialResult += item.assignments.count
        }

        todoAssignmentsCacheDescription = "当前状态：\(cache.value.count) 门课程，\(assignmentCount) 个作业，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }

    private func refreshExamSchedulesCacheDescription() {
        guard let cache = MMKVHelper.shared.examSchedulesCache else {
            examSchedulesCacheDescription = "当前状态：nil"
            return
        }

        examSchedulesCacheDescription = "当前状态：\(cache.value.count) 场考试，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }

    private func refreshCourseScheduleCacheDescription() {
        guard let cache = MMKVHelper.shared.courseScheduleCache else {
            courseScheduleCacheDescription = "当前状态：nil"
            return
        }

        let courseCount = cache.value.courses.count
        let sessionCount = cache.value.courses.reduce(into: 0) { partialResult, course in
            partialResult += course.sessions.count
        }
        let todayCoursesCount = CourseScheduleUtil.getUnfinishedCourses(
            semesterStartDate: cache.value.semesterStartDate,
            now: .now,
            courses: cache.value.courses
        ).count

        courseScheduleCacheDescription = "当前状态：\(cache.value.semester ?? "默认学期")，\(courseCount) 门课程，\(sessionCount) 个上课安排，今日可见 \(todayCoursesCount) 门，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }
}

private enum MockTodoAssignmentsFactory {
    static func makeTwoAssignmentsData(referenceDate: Date = .now) -> [TodoAssignmentsData] {
        [
            TodoAssignmentsData(
                course: .init(
                    id: "mock-course-todo-1",
                    name: "程序设计与算法分析",
                    number: "CS202",
                    department: "计算机学院",
                    teacher: "陈老师"
                ),
                assignments: [
                    .init(
                        id: 10001,
                        title: "实验报告：图的遍历",
                        publisher: "陈老师",
                        canSubmit: true,
                        submitStatus: false,
                        deadline: referenceDate.addingTimeInterval(6 * 3600),
                        startTime: referenceDate.addingTimeInterval(-2 * 24 * 3600)
                    )
                ]
            ),
            TodoAssignmentsData(
                course: .init(
                    id: "mock-course-todo-2",
                    name: "大学物理实验",
                    number: "PH114",
                    department: "理学院",
                    teacher: "刘老师"
                ),
                assignments: [
                    .init(
                        id: 10002,
                        title: "实验数据分析作业",
                        publisher: "刘老师",
                        canSubmit: true,
                        submitStatus: false,
                        deadline: referenceDate.addingTimeInterval(36 * 3600),
                        startTime: referenceDate.addingTimeInterval(-3 * 24 * 3600)
                    )
                ]
            ),
        ]
    }
}

private enum MockExamSchedulesFactory {
    static func makeFiveExamsData(referenceDate: Date = .now) -> [EduHelper.Exam] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: referenceDate)

        let todayExamStart = referenceDate
        let tomorrowExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart) ?? referenceDate
        let dayAfterTomorrowExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 2, to: todayStart) ?? todayStart) ?? referenceDate
        let threeDaysLaterExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 3, to: todayStart) ?? todayStart) ?? referenceDate
        let fiveDaysLaterExamStart = calendar.date(byAdding: .hour, value: 14, to: calendar.date(byAdding: .day, value: 5, to: todayStart) ?? todayStart) ?? referenceDate

        return [
            .init(
                campus: "云塘校区",
                session: "1",
                courseID: "EXAM-MOCK-001",
                courseName: "高等数学 B",
                teacher: "李老师",
                examTime: examTimeText(start: todayExamStart, durationHours: 2),
                examStartTime: todayExamStart,
                examEndTime: todayExamStart.addingTimeInterval(2 * 3600),
                examRoom: "文科楼 A-201",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "2",
                courseID: "EXAM-MOCK-002",
                courseName: "大学英语 IV",
                teacher: "周老师",
                examTime: examTimeText(start: tomorrowExamStart, durationHours: 2),
                examStartTime: tomorrowExamStart,
                examEndTime: tomorrowExamStart.addingTimeInterval(2 * 3600),
                examRoom: "综合实验楼 302",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "3",
                courseID: "EXAM-MOCK-003",
                courseName: "数据结构",
                teacher: "陈老师",
                examTime: examTimeText(start: dayAfterTomorrowExamStart, durationHours: 2),
                examStartTime: dayAfterTomorrowExamStart,
                examEndTime: dayAfterTomorrowExamStart.addingTimeInterval(2 * 3600),
                examRoom: "工科三号楼 105",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "4",
                courseID: "EXAM-MOCK-004",
                courseName: "马克思主义基本原理",
                teacher: "王老师",
                examTime: examTimeText(start: threeDaysLaterExamStart, durationHours: 2),
                examStartTime: threeDaysLaterExamStart,
                examEndTime: threeDaysLaterExamStart.addingTimeInterval(2 * 3600),
                examRoom: "金盆岭校区 2 教 401",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            .init(
                campus: "云塘校区",
                session: "5",
                courseID: "EXAM-MOCK-005",
                courseName: "大学物理 B",
                teacher: "赵老师",
                examTime: examTimeText(start: fiveDaysLaterExamStart, durationHours: 2),
                examStartTime: fiveDaysLaterExamStart,
                examEndTime: fiveDaysLaterExamStart.addingTimeInterval(2 * 3600),
                examRoom: "工科一号楼 208",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
        ]
    }

    private static func examTimeText(start: Date, durationHours: Int) -> String {
        let end = start.addingTimeInterval(TimeInterval(durationHours * 3600))
        return "\(start.formatted(date: .numeric, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))"
    }
}

private enum MockCourseScheduleFactory {
    static func makeEmptyCourseScheduleData(referenceDate: Date = .now) -> CourseScheduleData {
        CourseScheduleData(
            semester: semesterText(for: referenceDate),
            semesterStartDate: semesterStartDate(for: referenceDate),
            courses: []
        )
    }

    static func makeTodayFilledCourseScheduleData(referenceDate: Date = .now) -> CourseScheduleData {
        let today = CourseScheduleUtil.getDayOfWeek(referenceDate)
        let currentWeek = 1
        let weeks = [currentWeek]

        let courses: [EduHelper.Course] = [
            .init(
                courseName: "移动应用设计基础",
                groupName: "开发联调组 A",
                teacher: "周老师",
                sessions: [
                    .init(weeks: weeks, startSection: 1, endSection: 2, dayOfWeek: today, classroom: "云综教 A-101")
                ]
            ),
            .init(
                courseName: "SwiftUI 界面重构实训",
                groupName: "开发联调组 B",
                teacher: "陈老师",
                sessions: [
                    .init(weeks: weeks, startSection: 3, endSection: 4, dayOfWeek: today, classroom: "云综教 A-203")
                ]
            ),
            .init(
                courseName: "数据模型与缓存调试",
                groupName: "开发联调组 C",
                teacher: "刘老师",
                sessions: [
                    .init(weeks: weeks, startSection: 5, endSection: 6, dayOfWeek: today, classroom: "工科一号楼 305")
                ]
            ),
            .init(
                courseName: "课程组件样式验证",
                groupName: "开发联调组 D",
                teacher: "王老师",
                sessions: [
                    .init(weeks: weeks, startSection: 7, endSection: 8, dayOfWeek: today, classroom: "工科二号楼 410")
                ]
            ),
            .init(
                courseName: "全天场景覆盖测试",
                groupName: "开发联调组 E",
                teacher: "李老师",
                sessions: [
                    .init(weeks: weeks, startSection: 9, endSection: 10, dayOfWeek: today, classroom: "云综教 B-502")
                ]
            ),
        ]

        return CourseScheduleData(
            semester: semesterText(for: referenceDate),
            semesterStartDate: semesterStartDate(for: referenceDate),
            courses: courses
        )
    }

    private static func semesterStartDate(for referenceDate: Date) -> Date {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: referenceDate)
        let weekday = calendar.component(.weekday, from: todayStart)
        let daysSinceSunday = weekday - 1
        return calendar.date(byAdding: .day, value: -daysSinceSunday, to: todayStart) ?? todayStart
    }

    private static func semesterText(for referenceDate: Date) -> String {
        let year = Calendar.current.component(.year, from: referenceDate)
        return "\(year)-\(year + 1)-Mock"
    }
}
#endif
