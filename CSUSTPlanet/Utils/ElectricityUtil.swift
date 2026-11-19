//
//  ElectricityUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/18.
//

import CSUSTKit
import Foundation

enum ElectricityUtilError: LocalizedError {
    case campusNotFound
    case buildingNotFound
    case roomNotFound

    var errorDescription: String? {
        switch self {
        case .campusNotFound:
            return "未找到校区"
        case .buildingNotFound:
            return "未找到楼栋"
        case .roomNotFound:
            return "未找到宿舍"
        }
    }
}

enum ElectricityUtil {
    static let recentHistoryMonths = 3

    static func recentRecordsStartDate(referenceDate: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: -recentHistoryMonths, to: referenceDate) ?? referenceDate
    }

    static func getExhaustionInfo(from records: [ElectricityRecord]) -> String? {
        guard let predictionDate = ElectricityUtils.predictExhaustionDate(from: records) else { return nil }
        guard predictionDate > Date() else { return nil }

        return "预计\(predictionDate.formatted(.relative(presentation: .named)))电量耗尽"
    }

    static func getBuildings(
        _ campusCardHelper: CampusCardHelper,
        _ campus: Campus,
        useCache: Bool = true,
        retryProvider: AuthRetryProvider? = nil
    ) async throws -> [CampusCardHelper.Building] {
        if useCache, let buildings = MMKVHelper.ElectricityUtil.buildingsCache[campus] {
            return buildings
        }

        let buildings =
            if let retryProvider {
                try await retryProvider.withAuthRetry(system: .campusCard, maxRetries: 2) {
                    try await campusCardHelper.getBuildings(campus: campus)
                }
            } else {
                try await campusCardHelper.getBuildings(campus: campus)
            }

        MMKVHelper.ElectricityUtil.buildingsCache[campus] = buildings

        return buildings
    }

    static func getRooms(
        _ campusCardHelper: CampusCardHelper,
        _ building: CampusCardHelper.Building,
        useCache: Bool = true,
        retryProvider: AuthRetryProvider? = nil
    ) async throws -> [CampusCardHelper.Room] {
        if useCache, let rooms = MMKVHelper.ElectricityUtil.roomsCache[building] {
            return rooms
        }

        let rooms =
            if let retryProvider {
                try await retryProvider.withAuthRetry(system: .campusCard, maxRetries: 2) {
                    try await campusCardHelper.getRooms(building: building)
                }
            } else {
                try await campusCardHelper.getRooms(building: building)
            }

        MMKVHelper.ElectricityUtil.roomsCache[building] = rooms

        return rooms
    }

    static func getElectricity(
        _ campusCardHelper: CampusCardHelper,
        campusName: String,
        buildingName: String,
        roomName: String,
        useCache: Bool = true,
        retryProvider: AuthRetryProvider? = nil
    ) async throws -> Double {
        guard let campus = Campus(rawValue: campusName) else {
            throw ElectricityUtilError.campusNotFound
        }

        let buildings = try await getBuildings(campusCardHelper, campus, useCache: useCache, retryProvider: retryProvider)
        guard let building = buildings.first(where: { $0.name == buildingName }) else {
            throw ElectricityUtilError.buildingNotFound
        }

        let rooms = try await getRooms(campusCardHelper, building, useCache: useCache, retryProvider: retryProvider)
        guard let room = rooms.first(where: { $0.name == roomName }) else {
            throw ElectricityUtilError.roomNotFound
        }

        return if let retryProvider {
            try await retryProvider.withAuthRetry(system: .campusCard, maxRetries: 2) {
                try await campusCardHelper.getElectricity(room: room)
            }
        } else {
            try await campusCardHelper.getElectricity(room: room)
        }
    }
}

extension MMKVHelper {
    enum ElectricityUtil {
        @MMKVStorage(key: "ElectricityUtil.buildingsCache", defaultValue: [:])
        static var buildingsCache: [Campus: [CampusCardHelper.Building]]

        @MMKVStorage(key: "ElectricityUtil.roomsCache", defaultValue: [:])
        static var roomsCache: [CampusCardHelper.Building: [CampusCardHelper.Room]]
    }
}
