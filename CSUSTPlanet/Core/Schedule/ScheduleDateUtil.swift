//
//  ScheduleDateUtil.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import CSUSTKit
import Foundation

enum ScheduleDateUtil {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = CourseSchedulePresentation.calendar.timeZone
        calendar.firstWeekday = 1
        calendar.minimumDaysInFirstWeek = 1
        return calendar
    }()

    static let timeFormatter = makeDateFormatter(format: "HH:mm")
    static let dayNumberFormatter = makeDateFormatter(format: "d")
    static let weekdayFormatter = makeDateFormatter(format: "EEE")
    static let dateWithWeekdayFormatter = makeDateFormatter(format: "M月d日 EEEE")
    static let detailDateFormatter = makeDateFormatter(format: "yyyy年M月d日 EEEE")

    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    static func datesForWeek(containing date: Date) -> [Date] {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return ScheduleUtils.dates(ofWeek: 1, semesterStartDate: weekStart)
    }

    static func relativeDayTitle(for date: Date, referenceDate: Date) -> String? {
        let targetDay = startOfDay(for: date)
        let referenceDay = startOfDay(for: referenceDate)

        if isSameDay(targetDay, referenceDay) {
            return "今天"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: referenceDay),
            isSameDay(targetDay, tomorrow)
        {
            return "明天"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDay),
            isSameDay(targetDay, yesterday)
        {
            return "昨天"
        }

        return nil
    }

    static func eventDay(for event: ScheduleEvent) -> Date {
        startOfDay(for: event.timing.anchorDate)
    }

    static func makeDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
