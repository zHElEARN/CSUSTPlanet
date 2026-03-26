//
//  PlanetConfigService.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import Alamofire
import Foundation

enum PlanetConfigService {
    enum ConfigError: Error {
        case invalidBackendURL
    }

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
        let urlString = "\(Constants.backendHost)/config/campus-map"
        guard let url = URL(string: urlString) else {
            throw ConfigError.invalidBackendURL
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        return try await AF.request(request).serializingDecodable(GeoJSON.self).value
    }

    static func semesterCalendars() async throws -> [SchoolCalendar] {
        let urlString = "\(Constants.backendHost)/config/semester-calendars"
        guard let url = URL(string: urlString) else {
            throw ConfigError.invalidBackendURL
        }

        return try await AF.request(url).serializingDecodable([SchoolCalendar].self).value
    }

    static func semesterCalendar(semester: String) async throws -> SemesterCalendarConfig {
        let urlString = "\(Constants.backendHost)/config/semester-calendars/\(semester)"
        guard let url = URL(string: urlString) else {
            throw ConfigError.invalidBackendURL
        }

        return try await AF.request(url).serializingDecodable(SemesterCalendarConfig.self).value
    }
}
