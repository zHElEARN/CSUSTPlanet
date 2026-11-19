import Foundation
import GRDB

struct CustomScheduleEventGRDB: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable, Sendable {
    static let databaseTableName = "custom_schedule_events"

    var id: String = UUID().uuidString
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?

    enum Columns: String, ColumnExpression {
        case id, title, startDate, endDate, location, notes
    }
}
