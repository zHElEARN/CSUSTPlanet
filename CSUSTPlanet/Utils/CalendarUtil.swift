//
//  CalendarUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import EventKit
import Foundation

// MARK: - Error

enum CalendarUtilError: Error, LocalizedError {
    case eventPermissionDenied
    case reminderPermissionDenied
    case noAvailableSource
    case eventSourceUnavailable
    case eventCalendarCreationDenied(account: String)
    case noEventsToExport
    case fetchRemindersFailed

    var errorDescription: String? {
        switch self {
        case .eventPermissionDenied:
            return "日历权限被拒绝，请在设置中开启权限。"
        case .reminderPermissionDenied:
            return "提醒事项权限被拒绝，请在设置中开启权限。"
        case .noAvailableSource:
            return "未找到可用的日历账户，请前往系统设置添加 iCloud 或其他日历账户。"
        case .eventSourceUnavailable:
            return "所选日历账户已不可用，请重新打开导出窗口选择账户。"
        case .eventCalendarCreationDenied(let account):
            return "「\(account)」不允许新建日历，请选择另一个日历账户。"
        case .noEventsToExport:
            return "没有可导出的日历事件。"
        case .fetchRemindersFailed:
            return "获取提醒事项失败。"
        }
    }
}

// MARK: - CalendarUtil

actor CalendarUtil {
    static let shared = CalendarUtil()

    private let eventStore = EKEventStore()
    private let calendarTitlePrefix = "云岭星球 - "

    private init() {}

    struct EventAccount: Identifiable, Sendable {
        let id: String
        let title: String
    }
}

struct CalendarEventDraft: Sendable {
    let title: String
    let startDate: Date
    let endDate: Date
    let notes: String?
    let location: String?
    let timeZone: TimeZone?
    let alarmRelativeOffsets: [TimeInterval]
}

// MARK: - Permission

extension CalendarUtil {
    func requestReminderAccess() async throws -> Bool {
        return try await eventStore.requestFullAccessToReminders()
    }
}

// MARK: - Event

extension CalendarUtil {
    func eventAccounts() async throws -> [EventAccount] {
        try await requireEventAccess()
        let sources = eventStore.sources
        guard !sources.isEmpty else { throw CalendarUtilError.noAvailableSource }

        return
            sources
            .map { EventAccount(id: $0.sourceIdentifier, title: $0.title) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private func getOrCreateEventCalendar(suffix: String, accountID: String) throws -> EKCalendar {
        guard let source = eventStore.source(withIdentifier: accountID) else {
            throw CalendarUtilError.eventSourceUnavailable
        }

        let title = calendarTitlePrefix + suffix
        if let existingCalendar = source.calendars(for: .event).first(where: { $0.title == title }) {
            return existingCalendar
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = title
        newCalendar.source = source

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
        } catch let error as EKError where error.code == .sourceDoesNotAllowCalendarAddDelete {
            throw CalendarUtilError.eventCalendarCreationDenied(account: source.title)
        }

        return newCalendar
    }

    private func requireEventAccess() async throws {
        guard try await eventStore.requestFullAccessToEvents() else {
            throw CalendarUtilError.eventPermissionDenied
        }
    }

    func addEvents(_ drafts: [CalendarEventDraft], suffix: String, accountID: String) async throws {
        try await requireEventAccess()
        let calendar = try getOrCreateEventCalendar(suffix: suffix, accountID: accountID)
        for draft in drafts {
            guard !eventExists(draft, in: calendar) else { continue }
            try eventStore.save(makeEvent(from: draft, in: calendar), span: .thisEvent)
        }
    }

    /// 原子替换指定时间范围内的全部事件
    func replaceEvents(
        _ drafts: [CalendarEventDraft],
        suffix: String,
        accountID: String,
        from startDate: Date,
        to endDate: Date
    ) async throws {
        try await requireEventAccess()
        let calendar = try getOrCreateEventCalendar(suffix: suffix, accountID: accountID)

        do {
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: [calendar])
            for event in eventStore.events(matching: predicate) {
                try eventStore.remove(event, span: .thisEvent, commit: false)
            }

            for draft in drafts {
                try eventStore.save(makeEvent(from: draft, in: calendar), span: .thisEvent, commit: false)
            }

            try eventStore.commit()
        } catch {
            eventStore.reset()
            throw error
        }
    }

    private func eventExists(_ draft: CalendarEventDraft, in calendar: EKCalendar) -> Bool {
        let predicate = eventStore.predicateForEvents(withStart: draft.startDate, end: draft.endDate, calendars: [calendar])
        let events = eventStore.events(matching: predicate)
        return events.contains { $0.title == draft.title && $0.startDate == draft.startDate && $0.endDate == draft.endDate }
    }

    private func makeEvent(from draft: CalendarEventDraft, in calendar: EKCalendar) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = draft.title
        event.startDate = draft.startDate
        event.endDate = draft.endDate
        event.notes = draft.notes
        event.location = draft.location
        if let timeZone = draft.timeZone {
            event.timeZone = timeZone
        }
        event.calendar = calendar
        for offset in draft.alarmRelativeOffsets {
            event.addAlarm(EKAlarm(relativeOffset: offset))
        }
        return event
    }
}

// MARK: - Reminder

extension CalendarUtil {
    func getOrCreateReminderCalendar(suffix: String) async throws -> EKCalendar {
        let title = calendarTitlePrefix + suffix
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

    func addReminder(
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

    private func reminderExists(calendar: EKCalendar, title: String, dueDate: Date?) async throws -> Bool {
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
