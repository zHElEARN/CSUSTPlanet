import Foundation

enum ScheduleNotificationPlan {
    static let prefix = "schedule."
    private static let eventTimeFormatter = ScheduleDateUtil.makeDateFormatter(format: "M月d日 HH:mm")

    static func makeDrafts(
        events: [ScheduleEvent],
        rules: [ScheduleEventKind: ScheduleNotificationRule],
        now: Date
    ) -> [LocalNotificationDraft] {
        events.compactMap { event -> LocalNotificationDraft? in
            let rule = rules[event.kind] ?? .defaults(for: event.kind)
            guard rule.isEnabled else { return nil }

            let eventTime = event.timing.anchorDate
            let triggerDate = eventTime.addingTimeInterval(-rule.leadTime.seconds)
            guard triggerDate > now else { return nil }

            let thread = prefix + event.kind.rawValue
            let time = eventTimeFormatter.string(from: eventTime)
            let timingText: String =
                switch event.kind {
                case .assignment, .chaoxingAssignment: "\(time) 截止"
                case .electricity: "预计于 \(time) 耗尽"
                case .course, .physicsExperiment, .exam, .custom: "\(time) 开始"
                }
            let body = event.content.location.map { "\(timingText) · \($0)" } ?? timingText

            return LocalNotificationDraft(
                identifier: "\(thread).\(event.id)",
                threadIdentifier: thread,
                title: event.content.title,
                subtitle: event.content.subtitle ?? event.kind.presentationTitle,
                body: body,
                triggerDate: triggerDate,
                userInfo: [:]
            )
        }
        .sorted {
            if $0.triggerDate == $1.triggerDate {
                return $0.identifier < $1.identifier
            }
            return $0.triggerDate < $1.triggerDate
        }
    }
}
