//
//  CalendarUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import EventKit
import Foundation

// MARK: - Error

enum CalendarUtilError: Error, LocalizedError {
    case eventPermissionDenied
    case reminderPermissionDenied
    case noAvailableSource
    case fetchRemindersFailed

    var errorDescription: String? {
        switch self {
        case .eventPermissionDenied:
            return "日历权限被拒绝，请在设置中开启权限。"
        case .reminderPermissionDenied:
            return "提醒事项权限被拒绝，请在设置中开启权限。"
        case .noAvailableSource:
            return "未找到可用的日历账户，请前往系统设置添加 iCloud 或其他日历账户。"
        case .fetchRemindersFailed:
            return "获取提醒事项失败。"
        }
    }
}

// MARK: - CalendarUtil

enum CalendarUtil {
    private static let eventStore = EKEventStore()
}

// MARK: - Permission

extension CalendarUtil {
    static func requestEventAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToEvents()
    }

    static func requestReminderAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToReminders()
    }
}

// MARK: - Event

extension CalendarUtil {
    static func getOrCreateEventCalendar(named title: String) async throws -> EKCalendar {
        guard try await requestEventAccess() else { throw CalendarUtilError.eventPermissionDenied }

        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == title }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = title

        if let defaultListSource = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = defaultListSource
        } else if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            newCalendar.source = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            throw CalendarUtilError.noAvailableSource
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }

    static func addEvent(
        calendar: EKCalendar,
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil
    ) async throws {
        guard try await requestEventAccess() else { throw CalendarUtilError.eventPermissionDenied }
        guard try await !eventExists(calendar: calendar, title: title, startDate: startDate, endDate: endDate) else { return }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.calendar = calendar

        try eventStore.save(event, span: .thisEvent)
    }

    static private func eventExists(calendar: EKCalendar, title: String, startDate: Date, endDate: Date) async throws -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        let events = eventStore.events(matching: predicate)
        return events.contains { $0.title == title && $0.startDate == startDate && $0.endDate == endDate }
    }

    /// 清空指定日历中的所有事件
    static func clearCalendar(calendar: EKCalendar) async throws {
        guard try await requestEventAccess() else { throw CalendarUtilError.eventPermissionDenied }

        // 搜索前后两年的事件以确保清空
        let startDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let endDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
        let events = eventStore.events(matching: predicate)

        for event in events {
            try eventStore.remove(event, span: .thisEvent, commit: false)
        }
        try eventStore.commit()
    }

    /// 导出课程到日历
    static func addCoursesToCalendar(
        courses: [EduHelper.Course],
        semesterStartDate: Date,
        calendarTitle: String = "长理星球 - 课表"
    ) async throws {
        let calendar = try await getOrCreateEventCalendar(named: calendarTitle)

        // 可选：先清空原有课表，防止重复或旧数据干扰
        try await clearCalendar(calendar: calendar)

        let sysCalendar = Calendar.current

        for course in courses {
            for session in course.sessions {
                for week in session.weeks {
                    // 获取该周的所有日期（周日到周六）
                    let datesOfWeek = CourseScheduleUtil.getDatesForWeek(semesterStartDate: semesterStartDate, week: week)

                    // 匹配星期几
                    let targetDateIndex = session.dayOfWeek.rawValue  // Sunday=0, Monday=1...
                    guard targetDateIndex < datesOfWeek.count else { continue }
                    let targetDate = datesOfWeek[targetDateIndex]

                    // 获取时间的时分
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
                        let eventStartDate = sysCalendar.date(bySettingHour: startComponents[0], minute: startComponents[1], second: 0, of: targetDate),
                        let eventEndDate = sysCalendar.date(bySettingHour: endComponents[0], minute: endComponents[1], second: 0, of: targetDate)
                    else {
                        continue
                    }

                    let event = EKEvent(eventStore: eventStore)
                    event.title = course.courseName
                    event.startDate = eventStartDate
                    event.endDate = eventEndDate

                    var notes = "教师: \(course.teacher ?? "未知")"
                    if let groupName = course.groupName {
                        notes += "\n群组: \(groupName)"
                    }
                    notes += "\n周次: 第\(week)周"

                    event.notes = notes
                    event.location = session.classroom
                    event.calendar = calendar

                    try eventStore.save(event, span: .thisEvent, commit: false)
                }
            }
        }

        try eventStore.commit()
    }
}

// MARK: - Reminder

extension CalendarUtil {
    static func getOrCreateReminderCalendar(named title: String) async throws -> EKCalendar {
        guard try await requestReminderAccess() else { throw CalendarUtilError.reminderPermissionDenied }

        if let existingCalendar = eventStore.calendars(for: .reminder).first(where: { $0.title == title }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = title

        if let defaultListSource = eventStore.defaultCalendarForNewReminders()?.source {
            newCalendar.source = defaultListSource
        } else if let iCloudSource = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.contains("iCloud") }) {
            newCalendar.source = iCloudSource
        } else if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = localSource
        } else {
            throw CalendarUtilError.noAvailableSource
        }

        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }

    static func addReminder(
        calendar: EKCalendar,
        title: String,
        dueDate: Date?,
        notes: String? = nil
    ) async throws {
        guard try await requestReminderAccess() else { throw CalendarUtilError.reminderPermissionDenied }
        guard try await !reminderExists(calendar: calendar, title: title, dueDate: dueDate) else { return }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = calendar

        if let dueDate = dueDate {
            let dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = dueDateComponents
        }

        try eventStore.save(reminder, commit: true)
    }

    static private func reminderExists(calendar: EKCalendar, title: String, dueDate: Date?) async throws -> Bool {
        let reminders = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            let predicate = eventStore.predicateForReminders(in: [calendar])
            eventStore.fetchReminders(matching: predicate) { fetchedReminders in
                if let reminders = fetchedReminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: CalendarUtilError.fetchRemindersFailed)
                }
            }
        }

        return reminders.contains { reminder in
            guard reminder.title == title else {
                return false
            }

            let calendar = Calendar.current
            let existingDueDate: Date? = reminder.dueDateComponents.flatMap { calendar.date(from: $0) }

            if let dueDate = dueDate, let existingDueDate = existingDueDate {
                return calendar.compare(dueDate, to: existingDueDate, toGranularity: .minute) == .orderedSame
            } else {
                return dueDate == nil && existingDueDate == nil
            }
        }
    }
}
