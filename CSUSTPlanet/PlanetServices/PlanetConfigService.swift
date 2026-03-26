//
//  PlanetConfigService.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import Alamofire
import Foundation

enum PlanetConfigService {
    struct GeoJSON: Codable, Equatable {
        let type: String
        let features: [Feature]
    }

    struct Feature: Codable, Identifiable, Equatable, Hashable {
        let type: String
        let properties: FeatureProperties
        let geometry: FeatureGeometry

        var id: String { properties.name + properties.campus }
    }

    struct FeatureProperties: Codable, Hashable {
        let name: String
        let category: String
        let campus: String
    }

    struct FeatureGeometry: Codable, Hashable {
        let type: String
        let coordinates: [[[Double]]]
    }

    struct SchoolCalendar: Codable, Identifiable {
        var id: String { semesterCode }

        let semesterCode: String
        let title: String
        let subtitle: String
    }

    struct SemesterCalendarConfig: Codable {
        let semesterCode: String
        let title: String
        let subtitle: String
        let calendarStart: String
        let calendarEnd: String
        let semesterStart: String
        let semesterEnd: String
        let notes: [NoteConfig]
        let customWeekRanges: [CustomWeekRange]
    }

    struct NoteConfig: Codable {
        let row: Int
        let content: String
        let needNumber: Bool?
    }

    struct CustomWeekRange: Codable {
        let startRow: Int
        let endRow: Int
        let content: String
    }

    static func campusMap() async throws -> GeoJSON {
        return try await AF.request("\(Constants.backendHost)/config/campus-map", requestModifier: { $0.cachePolicy = .reloadIgnoringLocalCacheData }).serializingDecodable(GeoJSON.self).value
    }

    static func semesterCalendars() async throws -> [SchoolCalendar] {
        return try await AF.request("\(Constants.backendHost)/config/semester-calendars").serializingDecodable([SchoolCalendar].self).value
    }

    static func semesterCalendar(semester: String) async throws -> SemesterCalendarConfig {
        return try await AF.request("\(Constants.backendHost)/config/semester-calendars/\(semester)").serializingDecodable(SemesterCalendarConfig.self).value
    }
}
