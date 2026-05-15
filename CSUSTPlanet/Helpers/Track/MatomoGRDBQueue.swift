//
//  MatomoGRDBQueue.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/5/15.
//

import Foundation
import MatomoTracker
import OSLog

final class MatomoGRDBQueue: Queue {
    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "INF", negativeInfinity: "-INF", nan: "NAN")
        return encoder
    }()

    private let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "INF", negativeInfinity: "-INF", nan: "NAN")
        return decoder
    }()

    var eventCount: Int {
        return fetchEventCount()
    }

    private func fetchEventCount() -> Int {
        do {
            return try DatabaseManager.shared.poolThrows.read { db in
                return try MatomoEventGRDB.fetchCount(db)
            }
        } catch {
            Logger.matomoGRDBQueue.error("无法获取事件数量: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - Enqueue

    func enqueue(events: [Event], completion: (() -> Void)?) {
        do {
            try enqueue(events: events)
        } catch {
            Logger.matomoGRDBQueue.error("无法入队事件: \(error.localizedDescription)")
        }
        completion?()
    }

    private func enqueue(events: [Event]) throws {
        try DatabaseManager.shared.poolThrows.write { db in
            for event in events {
                var row = MatomoEventGRDB(id: event.uuid, payload: try jsonEncoder.encode(event), createdAt: .now)
                try row.insert(db)
            }
        }
    }

    // MARK: - First

    func first(limit: Int, completion: @escaping ([Event]) -> Void) {
        do {
            completion(try first(limit: limit))
        } catch {
            Logger.matomoGRDBQueue.error("无法获取事件: \(error.localizedDescription)")
            completion([])
        }
    }

    private func first(limit: Int) throws -> [Event] {
        return try DatabaseManager.shared.poolThrows.write { db in
            let rows =
                try MatomoEventGRDB
                .order(MatomoEventGRDB.Columns.createdAt.asc)
                .limit(limit)
                .fetchAll(db)

            var validEvents: [Event] = []
            var idsToDelete: [UUID] = []

            for row in rows {
                if let decoded = try? jsonDecoder.decode(Event.self, from: row.payload) {
                    validEvents.append(decoded)
                } else {
                    idsToDelete.append(row.id)
                }
            }

            if !idsToDelete.isEmpty {
                try MatomoEventGRDB.deleteAll(db, keys: idsToDelete)
                Logger.matomoGRDBQueue.warning("删除了 \(idsToDelete.count) 个无法解码的事件")
            }

            return validEvents
        }
    }

    // MARK: - Remove

    func remove(events: [Event], completion: @escaping () -> Void) {
        do {
            try remove(events: events)
        } catch {
            Logger.matomoGRDBQueue.error("无法删除事件: \(error.localizedDescription)")
        }
        completion()
    }

    private func remove(events: [Event]) throws {
        let ids = events.map { event in event.uuid }
        try DatabaseManager.shared.poolThrows.write { db in
            _ = try MatomoEventGRDB.deleteAll(db, ids: ids)
        }
    }
}

extension os.Logger {
    static let matomoGRDBQueue = Logger(appCategory: "MatomoGRDBQueue")
}
