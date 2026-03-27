//
//  PlanetConfigService.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import Alamofire
import Foundation

enum PlanetConfigService {
    enum AppPlatform: String, Codable {
        case ios
        case android
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

    struct Announcement: Codable, Identifiable, Equatable, Hashable {
        var id: String { "\(createdAt)-\(title)" }

        let title: String
        let content: String
        let isBanner: Bool
        let createdAt: String
    }

    struct AppVersion: Codable, Identifiable, Equatable, Hashable {
        var id: String { "\(platform.rawValue)-\(versionCode)" }

        let platform: AppPlatform
        let versionCode: Int
        let versionName: String
        let releaseNotes: String
        let downloadUrl: String
        let isForceUpdate: Bool
        let createdAt: String
    }

    struct CheckAppVersionResult: Codable, Equatable {
        let hasUpdate: Bool
        let isForceUpdate: Bool
        let latestVersion: AppVersion?
    }

    private static func get<T: Decodable>(
        _ path: String,
        parameters: Parameters? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) async throws -> T {
        return try await AF.request(
            "\(Constants.backendHost)\(path)",
            method: .get,
            parameters: parameters,
            encoding: URLEncoding.default,
            requestModifier: { request in
                if let cachePolicy {
                    request.cachePolicy = cachePolicy
                }
            }
        )
        .serializingDecodable(T.self)
        .value
    }

    static func campusMap() async throws -> GeoJSON {
        return try await get("/config/campus-map", cachePolicy: .reloadIgnoringLocalCacheData)
    }

    static func semesterCalendars() async throws -> [SchoolCalendar] {
        return try await get("/config/semester-calendars")
    }

    static func semesterCalendar(semester: String) async throws -> SemesterCalendarConfig {
        return try await get("/config/semester-calendars/\(semester)")
    }

    static func announcements() async throws -> [Announcement] {
        return try await get("/config/announcements")
    }

    static func appVersions(platform: AppPlatform) async throws -> [AppVersion] {
        return try await get(
            "/config/app-versions",
            parameters: ["platform": platform.rawValue]
        )
    }

    static func checkAppVersion(platform: AppPlatform, currentVersionCode: Int) async throws -> CheckAppVersionResult {
        return try await get(
            "/config/app-versions/check",
            parameters: [
                "platform": platform.rawValue,
                "currentVersionCode": currentVersionCode,
            ]
        )
    }
}
