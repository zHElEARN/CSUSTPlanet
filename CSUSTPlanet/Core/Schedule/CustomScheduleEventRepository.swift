import Foundation
import GRDB

enum CustomScheduleEventError: LocalizedError {
    case emptyTitle
    case invalidTimeRange
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .emptyTitle: "请输入日程标题。"
        case .invalidTimeRange: "结束时间须在当天且晚于开始时间。"
        case .recordNotFound: "这条日程已不存在。"
        }
    }
}

@MainActor
enum CustomScheduleEventRepository {
    static func fetch(id: String) async throws -> CustomScheduleEventGRDB {
        let database = try DatabaseManager.shared.poolThrows
        return try await database.read { db in
            guard let event = try CustomScheduleEventGRDB.fetchOne(db, key: id) else {
                throw CustomScheduleEventError.recordNotFound
            }
            return event
        }
    }

    static func save(_ event: CustomScheduleEventGRDB, isNew: Bool) async throws {
        guard !event.title.isEmpty else { throw CustomScheduleEventError.emptyTitle }
        guard event.startDate < event.endDate, ScheduleDateUtil.isSameDay(event.startDate, event.endDate) else {
            throw CustomScheduleEventError.invalidTimeRange
        }

        try await DatabaseManager.shared.poolThrows.write { db in
            if isNew {
                try event.insert(db)
            } else {
                do {
                    try event.update(db)
                } catch RecordError.recordNotFound {
                    throw CustomScheduleEventError.recordNotFound
                }
            }
        }
    }

    static func delete(id: String) async throws {
        try await DatabaseManager.shared.poolThrows.write { db in
            _ = try CustomScheduleEventGRDB.deleteOne(db, key: id)
        }
    }
}
