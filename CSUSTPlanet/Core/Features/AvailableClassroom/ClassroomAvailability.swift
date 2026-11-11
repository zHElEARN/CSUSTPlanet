//
//  ClassroomAvailability.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/11.
//

import CSUSTKit
import Foundation

/// 校区课表只请求一次；建立索引后，所有时间条件都在本地计算。
struct ClassroomScheduleSnapshot {
    private let sessionsByClassroom: [String: [EduHelper.ClassroomScheduleSession]]
    private let classroomNames: [String]
    let sectionCount: Int
    let weekCount: Int

    init(sessions: [EduHelper.ClassroomScheduleSession]) {
        sessionsByClassroom = Dictionary(grouping: sessions, by: \.classroom)
        classroomNames = sessionsByClassroom.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        sectionCount = max(10, sessions.map(\.endSection).max() ?? 10)
        weekCount = max(20, sessions.flatMap(\.weeks).max() ?? 20)
    }

    func rooms(week: Int, day: DayOfWeek) -> [ClassroomAvailability] {
        // 教室集合来自整学期，避免漏掉当天完全没有排课的教室。
        classroomNames.map {
            ClassroomAvailability(id: $0, allSessions: sessionsByClassroom[$0] ?? [], week: week, day: day, sectionCount: sectionCount)
        }
    }
}

struct ClassroomAvailability: Identifiable {
    let id: String
    let allSessions: [EduHelper.ClassroomScheduleSession]
    let sessions: [EduHelper.ClassroomScheduleSession]
    let sectionCount: Int
    let occupiedSections: Set<Int>

    static let weekdays: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    init(id: String, allSessions: [EduHelper.ClassroomScheduleSession], week: Int, day: DayOfWeek, sectionCount: Int) {
        self.id = id
        self.allSessions = allSessions
        self.sectionCount = sectionCount
        sessions = allSessions.filter { $0.weeks.contains(week) && $0.dayOfWeek == day }
            .sorted(by: Self.sessionOrder)
        occupiedSections = Set(sessions.flatMap { $0.startSection...$0.endSection })
    }

    func isAvailable(during range: ClosedRange<Int>) -> Bool {
        occupiedSections.isDisjoint(with: range)
    }

    /// 包含所选范围的最大连续空闲节次。
    func freeRange(containing range: ClosedRange<Int>) -> ClosedRange<Int>? {
        freeRanges.first { $0.lowerBound <= range.lowerBound && $0.upperBound >= range.upperBound }
    }

    var freeRanges: [ClosedRange<Int>] {
        var ranges: [ClosedRange<Int>] = []
        var start: Int?
        for section in 1...(sectionCount + 1) {
            if section <= sectionCount && !occupiedSections.contains(section) {
                if start == nil { start = section }
            } else if let first = start {
                ranges.append(first...(section - 1))
                start = nil
            }
        }
        return ranges
    }

    var freeSectionCount: Int {
        (1...sectionCount).filter { !occupiedSections.contains($0) }.count
    }

    func on(week: Int, day: DayOfWeek) -> Self {
        Self(id: id, allSessions: allSessions, week: week, day: day, sectionCount: sectionCount)
    }

    static func sessionOrder(_ lhs: EduHelper.ClassroomScheduleSession, _ rhs: EduHelper.ClassroomScheduleSession) -> Bool {
        if lhs.startSection != rhs.startSection { return lhs.startSection < rhs.startSection }
        if lhs.endSection != rhs.endSection { return lhs.endSection < rhs.endSection }
        return lhs.courseLabel < rhs.courseLabel
    }

    static func sectionLabel(_ range: ClosedRange<Int>) -> String {
        range.lowerBound == range.upperBound ? "第 \(range.lowerBound) 节" : "第 \(range.lowerBound)–\(range.upperBound) 节"
    }

    static func timeLabel(_ range: ClosedRange<Int>) -> String? {
        let times = CourseScheduleUtil.sectionTimeString
        guard range.lowerBound >= 1, range.upperBound <= times.count else { return nil }
        return "\(times[range.lowerBound - 1].0)–\(times[range.upperBound - 1].1)"
    }

    static func weeksLabel(_ weeks: [Int]) -> String {
        let sorted = Set(weeks).sorted()
        var parts: [String] = []
        var index = 0
        while index < sorted.count {
            let start = sorted[index]
            var end = start
            index += 1
            while index < sorted.count && sorted[index] == end + 1 {
                end = sorted[index]
                index += 1
            }
            parts.append(start == end ? "\(start)" : "\(start)–\(end)")
        }
        return "第 \(parts.joined(separator: "、")) 周"
    }
}
