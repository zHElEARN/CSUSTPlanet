import Foundation

enum ScheduleNotificationLeadTime: Int, Codable, CaseIterable, Hashable {
    case atTime = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120
    case sixHours = 360
    case twelveHours = 720
    case oneDay = 1440
    case twoDays = 2880

    var seconds: TimeInterval { TimeInterval(rawValue * 60) }

    var title: String {
        switch self {
        case .atTime:
            "到点提醒"
        case .fiveMinutes, .tenMinutes, .fifteenMinutes, .thirtyMinutes:
            "提前 \(rawValue) 分钟"
        case .oneHour, .twoHours, .sixHours, .twelveHours:
            "提前 \(rawValue / 60) 小时"
        case .oneDay, .twoDays:
            "提前 \(rawValue / 1440) 天"
        }
    }
}

struct ScheduleNotificationRule: Codable, Equatable {
    var isEnabled = true
    var leadTime: ScheduleNotificationLeadTime

    static func defaults(for kind: ScheduleEventKind) -> Self {
        let leadTime: ScheduleNotificationLeadTime =
            switch kind {
            case .course, .custom: .fifteenMinutes
            case .physicsExperiment: .thirtyMinutes
            case .exam, .assignment, .chaoxingAssignment: .oneHour
            case .electricity: .oneDay
            }
        return Self(leadTime: leadTime)
    }
}

extension MMKVHelper {
    enum ScheduleNotifications {
        @MMKVStorage(key: "ScheduleNotifications.isEnabled", defaultValue: false)
        static var isEnabled: Bool

        @MMKVStorage(key: "ScheduleNotifications.rules", defaultValue: [:])
        static var rules: [ScheduleEventKind: ScheduleNotificationRule]
    }
}
