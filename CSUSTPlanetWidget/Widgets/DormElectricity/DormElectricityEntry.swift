//
//  DormElectricityEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/20.
//

import WidgetKit

struct DormElectricityEntry: TimelineEntry {
    let date: Date
    let configuration: DormElectricityAppIntent

    struct Record: Identifiable {
        var id: Date { date }
        let electricity: Double
        let date: Date
    }
    let records: [Record]

    let lastFetchDate: Date?

    var last: Record? {
        guard let lastFetchDate = lastFetchDate, let lastRecord = records.last else { return nil }
        return Record(electricity: lastRecord.electricity, date: lastFetchDate)
    }
    var bounds: (min: Double, max: Double)? {
        guard let firstValue = records.first?.electricity else { return nil }
        return records.reduce((min: firstValue, max: firstValue)) { result, record in
            (min(result.min, record.electricity), max(result.max, record.electricity))
        }
    }

    static let mockEntry = DormElectricityEntry(
        date: .now,
        configuration: .mockIntent,
        records: [
            Record(electricity: 30, date: .now.addingTimeInterval(-86400)),
            Record(electricity: 20, date: .now.addingTimeInterval(-43200)),
            Record(electricity: 10, date: .now.addingTimeInterval(-21600)),
        ],
        lastFetchDate: .now
    )
}
