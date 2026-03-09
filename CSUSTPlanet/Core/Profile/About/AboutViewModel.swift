//
//  AboutViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import Foundation
import Sentry
import SwiftData

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

        // 生成待提交作业
        let mockAssignments = UrgentCoursesData(courses: [
            UrgentCoursesData.Course(name: "马克思主义基本原理课外实践", id: "1"),
            UrgentCoursesData.Course(name: "大学物理B（下）", id: "2"),
            UrgentCoursesData.Course(name: "大数据存储与管理实验A", id: "2"),
        ])
        MMKVHelper.shared.urgentCoursesCache = Cached(cachedAt: today, value: mockAssignments)

        // 生成考试安排
        let mockExams = [
            EduHelper.Exam(
                campus: "金盆岭校区",
                session: "2025-2026-2",
                courseID: "",
                courseName: "程序设计算法与数据结构（三）",
                teacher: "",
                examTime: "2026-02-15 09:00-11:00",
                examStartTime: calendar.date(byAdding: .day, value: 4, to: calendar.startOfDay(for: today))!.addingTimeInterval(9 * 3600),
                examEndTime: calendar.date(byAdding: .day, value: 4, to: calendar.startOfDay(for: today))!.addingTimeInterval(11 * 3600),
                examRoom: "金1教-4机房",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            EduHelper.Exam(
                campus: "金盆岭校区",
                session: "2025-2026-2",
                courseID: "",
                courseName: "离散结构",
                teacher: "",
                examTime: "2026-02-18 14:00-16:00",
                examStartTime: calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: today))!.addingTimeInterval(14 * 3600),
                examEndTime: calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: today))!.addingTimeInterval(16 * 3600),
                examRoom: "金12-300",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
            EduHelper.Exam(
                campus: "金盆岭校区",
                session: "2025-2026-2",
                courseID: "",
                courseName: "操作系统",
                teacher: "刘教授",
                examTime: "2026-02-20 09:00-11:00",
                examStartTime: calendar.date(byAdding: .day, value: 9, to: calendar.startOfDay(for: today))!.addingTimeInterval(9 * 3600),
                examEndTime: calendar.date(byAdding: .day, value: 9, to: calendar.startOfDay(for: today))!.addingTimeInterval(11 * 3600),
                examRoom: "金12-108",
                seatNumber: "",
                admissionTicketNumber: "",
                remarks: ""
            ),
        ]
        MMKVHelper.shared.examSchedulesCache = Cached(cachedAt: today, value: mockExams)

        // 宿舍电量
        let context = SharedModelUtil.mainContext

        let dormDescriptor = FetchDescriptor<Dorm>()
        var targetDorm: Dorm?
        if let dorms = try? context.fetch(dormDescriptor) {
            for dorm in dorms {
                if dorm.room == "A233" && dorm.campusID == CampusCardHelper.Campus.yuntang.id {
                    targetDorm = dorm
                }
            }
        }

        if targetDorm == nil {
            targetDorm = Dorm(room: "A233", building: CampusCardHelper.Building(name: "至诚轩5栋A区", id: "1", campus: .yuntang))
            if let targetDorm = targetDorm {
                context.insert(targetDorm)
            }
        }

        if let dorm = targetDorm {
            let dormID = dorm.id
            let electricityPredicate = #Predicate<ElectricityRecord> { $0.dorm?.id == dormID }
            let electricityDescriptor = FetchDescriptor<ElectricityRecord>(predicate: electricityPredicate)
            if let records = try? context.fetch(electricityDescriptor) {
                for record in records {
                    context.delete(record)
                }
            }

            var currentElectricity = Double.random(in: 80...100)

            for i in (0..<10).reversed() {
                let recordDate = calendar.date(byAdding: .day, value: -i, to: today)!
                let consumption = Double.random(in: 2.0...5.0)
                currentElectricity -= consumption
                let finalElectricity = max(0, currentElectricity)
                let record = ElectricityRecord(electricity: finalElectricity, date: recordDate, dorm: dorm)
                context.insert(record)
                if i == 0 {
                    dorm.lastFetchElectricity = finalElectricity
                    dorm.lastFetchDate = recordDate
                }
            }
            try? context.save()
        }
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

    func captureTestError() {
        SentrySDK.capture(message: "Test Error")
    }
    #endif
}
