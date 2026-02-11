//
//  AnnualReviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import Foundation
import SwiftData

@MainActor
final class AnnualReviewViewModel: ObservableObject {
    // MARK: - Properties

    /// 当前年度
    private let year = 2025
    /// 上半年学期
    private lazy var semester1 = "\(year-1)-\(year)-2"
    /// 下半年学期
    private lazy var semester2 = "\(year)-\(year+1)-1"

    func compute() {
        Task {
            // MARK: - 获取数据

            guard let eduHelper = AuthManager.shared.eduHelper else {
                debugPrint("EduHelper为空")
                return
            }
            guard let moocHelper = AuthManager.shared.moocHelper else {
                debugPrint("MoocHelper为空")
                return
            }
            guard let eduProfile = try? await eduHelper.profileService.getProfile() else {
                debugPrint("获取EduHelper个人信息失败")
                return
            }
            // 上半年学期成绩
            guard let semester1Grades = try? await eduHelper.courseService.getCourseGrades(academicYearSemester: semester1) else {
                debugPrint("获取\(semester1)成绩失败")
                return
            }
            // 下半年学期成绩
            guard let semester2Grades = try? await eduHelper.courseService.getCourseGrades(academicYearSemester: semester2) else {
                debugPrint("获取\(semester2)成绩失败")
                return
            }
            let allGrades = semester1Grades + semester2Grades
            // 上半年课程表
            guard let semester1Courses = try? await eduHelper.courseService.getCourseSchedule(academicYearSemester: semester1) else {
                debugPrint("获取\(semester1)课程表失败")
                return
            }
            // 下半年课程表
            guard let semester2Courses = try? await eduHelper.courseService.getCourseSchedule(academicYearSemester: semester2) else {
                debugPrint("获取\(semester2)课程表失败")
                return
            }
            let allCourses = semester1Courses + semester2Courses
            guard let moocProfile = try? await moocHelper.getProfile() else {
                debugPrint("获取MoocHelper个人信息失败")
                return
            }
            let dormDescriptor = FetchDescriptor<Dorm>()
            guard let dorms = try? SharedModelUtil.context.fetch(dormDescriptor) else {
                debugPrint("获取宿舍信息失败")
                return
            }

            // MARK: - 计算数据

            // MARK: - 个人信息

            /// 名字
            let name = eduProfile.name
            /// 名字拼音
            let namePinyin = eduProfile.namePinyin
            /// 院系
            let department = eduProfile.department
            /// 专业
            let major = eduProfile.major
            /// 班级
            let className = eduProfile.className
            /// 学号
            let studentID = eduProfile.studentID
            /// 入学日期
            let enrollmentDate = eduProfile.enrollmentDate

            debugPrint("名字", name)
            debugPrint("名字拼音", namePinyin)
            debugPrint("院系", department)
            debugPrint("专业", major)
            debugPrint("班级", className)
            debugPrint("学号", studentID)
            debugPrint("入学日期", enrollmentDate)

            // MARK: - 成绩

            /// 年度总 GPA
            let annualGPA = calculateGPA(allGrades)
            /// 考试课程数量
            let examCount = allGrades.filter { $0.assessmentMethod == "考试" }.count
            /// 考查课程数量
            let assessmentCount = allGrades.filter { $0.assessmentMethod == "考查" }.count
            /// 满绩科目 (绩点 4.0)
            let fullGradePointCourses = allGrades.filter { $0.gradePoint >= 4.0 }
            /// 刚好及格科目 (绩点 1.0)
            let justPassedCourses = allGrades.filter { $0.gradePoint == 1.0 }
            /// 挂科科目 (绩点 0.0)
            let failedCourses = allGrades.filter { $0.gradePoint == 0.0 }
            /// 成绩最高分课程 (取第一条)
            let highestGradeCourse = allGrades.max(by: { $0.grade < $1.grade })
            /// 年度总学分
            let totalCredits = allGrades.reduce(0.0) { $0 + $1.credit }
            /// 年度总课程数
            let totalCoursesCount = allGrades.count

            debugPrint("年度总 GPA", annualGPA)
            debugPrint("考试课程数量", examCount)
            debugPrint("考查课程数量", assessmentCount)
            debugPrint("满绩科目", fullGradePointCourses.count)
            debugPrint("刚好及格科目", justPassedCourses.count)
            debugPrint("挂科科目", failedCourses.count)
            debugPrint("成绩最高分课程", highestGradeCourse?.courseName ?? "无")
            debugPrint("年度总学分", totalCredits)
            debugPrint("年度总课程数", totalCoursesCount)

            // MARK: - 课表

            let allSessions = allCourses.flatMap { $0.sessions }

            /// 早八节次数量
            let earlyMorningCoursesCount =
                allSessions
                .filter { $0.startSection == 1 }
                .map { $0.weeks.count }
                .reduce(0, +)
            /// 各星期上课频次（字典：[星期几: 次数]）
            let dailyClassFrequency =
                allSessions
                .reduce(into: [EduHelper.DayOfWeek: Int]()) { result, session in
                    result[session.dayOfWeek, default: 0] += session.weeks.count
                }
            /// 老师上课次数排行
            let teacherRanking =
                allCourses
                .reduce(into: [String: Int]()) { result, course in
                    if let teacherName = course.teacher {
                        let classCount = course.sessions.reduce(0) { $0 + $1.weeks.count }
                        result[teacherName, default: 0] += classCount
                    }
                }
                .sorted { $0.value > $1.value }
                .map { (teacher: $0.key, count: $0.value) }
            /// 周末上课次数
            let weekendCoursesCount =
                allSessions
                .filter { $0.dayOfWeek == .saturday || $0.dayOfWeek == .sunday }
                .map { $0.weeks.count }
                .reduce(0, +)
            /// 晚课上课次数
            let eveningCoursesCount =
                allSessions
                .filter { $0.startSection == 9 && $0.endSection == 10 }
                .map { $0.weeks.count }
                .reduce(0, +)
            /// 总学时（分钟）
            let totalStudyMinutes =
                allSessions
                .map { ($0.endSection - $0.startSection + 1) * 45 * $0.weeks.count }
                .reduce(0, +)
            /// 教学楼去往频次（字典：[建筑名: 次数]）
            let buildingFrequency =
                allSessions
                .reduce(into: [String: Int]()) { result, session in
                    if let classroom = session.classroom {
                        let buildingName = extractBuilding(from: classroom)
                        result[buildingName, default: 0] += session.weeks.count
                    }
                }

            debugPrint("早八节次数量", earlyMorningCoursesCount)
            debugPrint("各星期上课次数", dailyClassFrequency)
            debugPrint("老师上课次数排行", teacherRanking)
            debugPrint("周末上课次数", weekendCoursesCount)
            debugPrint("晚课上课次数", eveningCoursesCount)
            debugPrint("总学时（分钟）", totalStudyMinutes)
            debugPrint("教学楼去往频次", buildingFrequency)

            // MARK: - 网络课程平台

            /// 网络课程平台总在线时长（分钟）
            let moocTotalOnlineMinutes = parseOnlineTime(moocProfile.totalOnlineTime)
            /// 网络课程平台登录次数
            let moocLoginCount = moocProfile.loginCount

            debugPrint("网络课程平台总在线时长（分钟）", moocTotalOnlineMinutes)
            debugPrint("网络课程平台登录次数", moocLoginCount)

            // MARK: - 宿舍

            /// 每个宿舍的电量统计数据（数组：包含宿舍模型、最低记录、最高记录、充电次数）
            let dormElectricityStats = dorms.compactMap {
                dorm -> (
                    dorm: Dorm,
                    minRecord: ElectricityRecord,
                    maxRecord: ElectricityRecord,
                    chargeCount: Int
                )? in
                guard let records = dorm.records, !records.isEmpty else {
                    return nil
                }
                let chronologicalRecords = records.sorted { $0.date < $1.date }
                let minRecord = chronologicalRecords.min { $0.electricity < $1.electricity }!
                let maxRecord = chronologicalRecords.max { $0.electricity < $1.electricity }!
                let chargeCount = zip(chronologicalRecords, chronologicalRecords.dropFirst())
                    .filter { previous, current in
                        current.electricity > previous.electricity
                    }
                    .count
                return (dorm, minRecord, maxRecord, chargeCount)
            }
            debugPrint("宿舍电量统计数据", dormElectricityStats)
        }
    }

    // MARK: - Helper Methods

    private func calculateGPA(_ grades: [EduHelper.CourseGrade]) -> Double {
        let totalCredits = grades.reduce(0.0) { $0 + $1.credit }
        guard totalCredits > 0 else { return 0.0 }
        return grades.reduce(0.0) { $0 + $1.gradePoint * $1.credit } / totalCredits
    }

    private func parseOnlineTime(_ timeString: String) -> Int {
        var totalMinutes = 0
        let hoursPattern = #"(\d+)小时"#
        let minutesPattern = #"(\d+)分"#

        if let hoursRange = timeString.range(of: hoursPattern, options: .regularExpression) {
            let hoursStr = timeString[hoursRange].replacingOccurrences(of: "小时", with: "")
            totalMinutes += (Int(hoursStr) ?? 0) * 60
        }

        if let minutesRange = timeString.range(of: minutesPattern, options: .regularExpression) {
            let minutesStr = timeString[minutesRange].replacingOccurrences(of: "分", with: "")
            totalMinutes += Int(minutesStr) ?? 0
        }

        return totalMinutes
    }

    private func extractBuilding(from classroom: String) -> String {
        var buildingPart: String
        if let hyphenIndex = classroom.firstIndex(of: "-") {
            buildingPart = String(classroom[..<hyphenIndex])
        } else {
            buildingPart = classroom
        }

        if let range = buildingPart.range(of: "[A-Z]$", options: .regularExpression) {
            buildingPart.removeSubrange(range)
        }

        if !classroom.contains("-") {
            buildingPart = buildingPart.trimmingCharacters(in: .decimalDigits)
        }

        return buildingPart
    }
}
