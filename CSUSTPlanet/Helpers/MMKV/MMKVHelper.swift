//
//  MMKVHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import CSUSTKit
import Foundation
import OSLog
import Sentry

#if canImport(MMKV)
import MMKV
#elseif canImport(MMKVAppExtension)
import MMKVAppExtension
#endif

struct Cached<T: Codable>: Codable {
    let cachedAt: Date
    let value: T
}

// MARK: - Properties

class MMKVHelper {
    static let shared = MMKVHelper()

    private init() {}

    private let logHandler = LogHandler()

    lazy var mmkv: MMKV = {
        let mmkvDirectoryURL = Constants.mmkvDirectoryURL

        MMKV.initialize(rootDir: mmkvDirectoryURL.path, logLevel: .info, handler: self.logHandler)
        guard
            let instance = MMKV(
                mmapID: Constants.mmkvID,
                cryptKey: nil,
                rootPath: mmkvDirectoryURL.path,
                mode: .multiProcess,
                expectedCapacity: 0
            )
        else {
            SentrySDK.capture(message: "无法初始化MMKV实例ID: \(Constants.mmkvID)")
            fatalError("Failed to initialize MMKV with ID: \(Constants.mmkvID)")
        }

        return instance
    }()

    let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NAN"
        )
        return encoder
    }()

    let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NAN"
        )
        return decoder
    }()

    // MARK: - GlobalVars properties

    @MMKVStorage(key: "GlobalVars.appearance", defaultValue: "system")
    var appearance: String

    @MMKVStorage(key: "GlobalVars.isUserAgreementAccepted", defaultValue: false)
    var isUserAgreementAccepted: Bool

    @MMKVStorage(key: "GlobalVars.hasLaunchedBefore", defaultValue: false)
    var hasLaunchedBefore: Bool

    @MMKVStorage(key: "GlobalVars.isLiveActivityEnabled", defaultValue: true)
    var isLiveActivityEnabled: Bool

    @MMKVStorage(key: "GlobalVars.isWebVPNModeEnabled", defaultValue: false)
    var isWebVPNModeEnabled: Bool

    @MMKVStorage(key: "GlobalVars.isNotificationEnabled", defaultValue: false)
    var isNotificationEnabled: Bool

    @MMKVOptionalStorage(key: "GlobalVars.userId")
    var userId: String?

    @MMKVStorage(key: "GlobalVars.hasCleanedUpDuplicateElectricityRecords", defaultValue: false)
    var hasCleanedUpDuplicateElectricityRecords: Bool

    // MARK: - Cached Properties

    @MMKVOptionalStorage(key: "Cached.courseGradesCache")
    var courseGradesCache: Cached<[EduHelper.CourseGrade]>?

    @MMKVOptionalStorage(key: "Cached.urgentCoursesCache")
    var urgentCoursesCache: Cached<UrgentCoursesData>?

    @MMKVOptionalStorage(key: "Cached.examSchedulesCache")
    var examSchedulesCache: Cached<[EduHelper.Exam]>?

    @MMKVOptionalStorage(key: "Cached.courseScheduleCache")
    var courseScheduleCache: Cached<CourseScheduleData>?

    @MMKVOptionalStorage(key: "Cached.physicsExperimentScheduleCache")
    var physicsExperimentScheduleCache: Cached<[PhysicsExperimentHelper.Course]>?

    // MARK: - CampusMap Properties

    @MMKVOptionalStorage(key: "CampusMap.selectedCampus")
    var selectedCampus: CampusCardHelper.Campus?
}

// MARK: - Calendar Sync

extension MMKVHelper {
    enum CourseSchedule {
        enum CalendarSync {
            @MMKVOptionalStorage(key: "CourseSchedule.CalendarSync.exportScopeLimit")
            static var exportScopeLimit: Int?

            @MMKVOptionalStorage(key: "CourseSchedule.CalendarSync.firstReminderOffset")
            static var firstReminderOffset: Double?

            @MMKVOptionalStorage(key: "CourseSchedule.CalendarSync.secondReminderOffset")
            static var secondReminderOffset: Double?
        }
    }
}

// MARK: - Todo Assignments

extension MMKVHelper {
    enum TodoAssignments {
        @MMKVOptionalStorage(key: "TodoAssignments.cache")
        static var cache: Cached<[TodoAssignmentsData]>?
    }
}

// MARK: - Swift Data

extension MMKVHelper {
    enum SwiftData {
        @MMKVStorage(key: "SwiftData.databaseVersion", defaultValue: 0)
        static var databaseVersion: Int

        @MMKVStorage(key: "SwiftData.hasMigratedToGRDB", defaultValue: false)
        static var hasMigratedToGRDB: Bool
    }
}

// MARK: - Planet Service

extension MMKVHelper {
    enum PlanetService {
        @MMKVOptionalStorage(key: "PlanetService.authToken")
        static var authToken: String?
    }
}

// MARK: - Methods

extension MMKVHelper {
    func clearAll() {
        mmkv.clearAll()
    }

    func removeValue(forKey key: String) {
        mmkv.removeValue(forKey: key)
    }
}
