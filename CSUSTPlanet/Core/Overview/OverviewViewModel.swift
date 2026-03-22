//
//  OverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import GRDB
import SwiftUI

@MainActor
@Observable
class OverviewViewModel {
    // MARK: - 基本数据
    private var gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?
    private var examScheduleData: Cached<[EduHelper.Exam]>?
    private var courseScheduleData: Cached<CourseScheduleData>?
    private var urgentCoursesData: Cached<UrgentCoursesData>?
    var primaryDorm: DormGRDB?
    var electricityExhaustionInfo: String?

    private var dormObserver: AutoRefreshingObserver?

    // MARK: - 计算数据

    /// 学期和周数信息
    var weekInfo: String? {
        guard let data = courseScheduleData?.value else { return nil }
        let semester = data.semester ?? "默认学期"

        if let currentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.semesterStartDate, now: .now) {
            return "\(semester) 第\(currentWeek)周"
        }
        return semester
    }

    /// 成绩分析数据
    var gradeAnalysis: GradeAnalysisData? {
        guard let courseGrades = gradeAnalysisData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    /// 未结束的考试
    var pendingExams: [EduHelper.Exam] {
        guard let examData = examScheduleData?.value else { return [] }
        return examData.filter { .now <= $0.examEndTime }
    }

    /// 有未提交作业的课程
    var urgentCourses: [UrgentCoursesData.Course] {
        guard let data = urgentCoursesData?.value else { return [] }
        return data.courses
    }

    enum CourseDisplayState {
        case loading  // No data available
        case beforeSemester(days: Int?)
        case inSemester(courses: [(course: CourseDisplayInfo, isCurrent: Bool)])
        case afterSemester
    }

    /// 课程表显示状态
    var courseDisplayState: CourseDisplayState {
        guard let data = courseScheduleData?.value else { return .loading }

        let status = CourseScheduleUtil.getSemesterStatus(semesterStartDate: data.semesterStartDate, date: .now)

        switch status {
        case .beforeSemester:
            let days = CourseScheduleUtil.getDaysUntilSemesterStart(semesterStartDate: data.semesterStartDate, currentDate: .now)
            return .beforeSemester(days: days)
        case .afterSemester:
            return .afterSemester
        case .inSemester:
            let courses = CourseScheduleUtil.getUnfinishedCourses(
                semesterStartDate: data.semesterStartDate,
                now: .now,
                courses: data.courses
            )
            return .inSemester(courses: courses)
        }
    }

    // MARK: - 辅助函数

    func onAppear() {
        gradeAnalysisData = MMKVHelper.shared.courseGradesCache
        examScheduleData = MMKVHelper.shared.examSchedulesCache
        courseScheduleData = MMKVHelper.shared.courseScheduleCache
        urgentCoursesData = MMKVHelper.shared.urgentCoursesCache

        observePrimaryDorm()
    }

    private func observePrimaryDorm() {
        guard let pool = DatabaseManager.shared.pool else {
            primaryDorm = nil
            electricityExhaustionInfo = nil
            return
        }

        struct ProcessedDormOverviewData {
            let dorm: DormGRDB?
            let exhaustionInfo: String?
        }

        dormObserver = AutoRefreshingObserver { [weak self] in
            let observation = ValueObservation.tracking { db -> (DormGRDB?, [ElectricityRecordGRDB]) in
                let favoriteDorm = try DormGRDB
                    .filter(DormGRDB.Columns.isFavorite == true)
                    .fetchOne(db)

                let dorm = try favoriteDorm ?? DormGRDB.order(DormGRDB.Columns.id.asc).fetchOne(db)
                guard let dormID = dorm?.id else { return (dorm, []) }

                let records = try ElectricityRecordGRDB
                    .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                    .order(ElectricityRecordGRDB.Columns.date.asc)
                    .fetchAll(db)

                return (dorm, records)
            }
            .map { dorm, records in
                ProcessedDormOverviewData(
                    dorm: dorm,
                    exhaustionInfo: ElectricityUtil.getExhaustionInfo(from: records)
                )
            }

            return observation.start(
                in: pool,
                scheduling: .immediate,
                onError: { _ in
                    Task { @MainActor in
                        self?.primaryDorm = nil
                        self?.electricityExhaustionInfo = nil
                    }
                },
                onChange: { [weak self] data in
                    Task { @MainActor in
                        withAnimation(.snappy) {
                            self?.primaryDorm = data.dorm
                            self?.electricityExhaustionInfo = data.exhaustionInfo
                        }
                    }
                }
            )
        }
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }

    func formatCourseTime(_ startSection: Int, _ endSection: Int) -> String {
        let startIndex = startSection - 1
        let endIndex = endSection - 1

        guard startIndex >= 0 && startIndex < CourseScheduleUtil.sectionTimeString.count,
            endIndex >= 0 && endIndex < CourseScheduleUtil.sectionTimeString.count
        else {
            return "时间未知"
        }

        return "\(CourseScheduleUtil.sectionTimeString[startIndex].0) - \(CourseScheduleUtil.sectionTimeString[endIndex].1)"
    }
}
