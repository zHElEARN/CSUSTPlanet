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

import MMKV

struct Cached<T: Codable>: Codable {
    let cachedAt: Date
    let value: T
}

// MARK: - Properties

class MMKVHelper {
    static let shared = MMKVHelper()

    private init() {}

    private let logHandler = LogHandler()

    private lazy var mmkv: MMKV = {
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

    private let jsonEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NAN"
        )
        return encoder
    }()

    private let jsonDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "INF",
            negativeInfinity: "-INF",
            nan: "NAN"
        )
        return decoder
    }()
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

// MARK: - Setters

extension MMKVHelper {
    private func set(forKey key: String, _ value: String) {
        mmkv.set(value, forKey: key)
    }

    private func set(forKey key: String, _ value: Int) {
        mmkv.set(Int64(value), forKey: key)
    }

    private func set(forKey key: String, _ value: Bool) {
        mmkv.set(value, forKey: key)
    }

    private func set(forKey key: String, _ value: Float) {
        mmkv.set(value, forKey: key)
    }

    private func set(forKey key: String, _ value: Double) {
        mmkv.set(value, forKey: key)
    }

    private func set(forKey key: String, _ value: Data) {
        mmkv.set(value, forKey: key)
    }

    private func set<Type: Encodable>(forKey key: String, _ value: Type) {
        if let data = try? jsonEncoder.encode(value) {
            mmkv.set(data, forKey: key)
        }
    }
}

// MARK: - Getters

extension MMKVHelper {
    private func string(forKey key: String) -> String? {
        mmkv.string(forKey: key)
    }

    private func int(forKey key: String) -> Int? {
        if mmkv.contains(key: key) {
            return Int(mmkv.int64(forKey: key))
        }
        return nil
    }

    private func bool(forKey key: String) -> Bool? {
        if mmkv.contains(key: key) {
            return mmkv.bool(forKey: key)
        }
        return nil
    }

    private func float(forKey key: String) -> Float? {
        if mmkv.contains(key: key) {
            return mmkv.float(forKey: key)
        }
        return nil
    }

    private func double(forKey key: String) -> Double? {
        if mmkv.contains(key: key) {
            return mmkv.double(forKey: key)
        }
        return nil
    }

    private func data(forKey key: String) -> Data? {
        return mmkv.data(forKey: key)
    }

    private func object<Type: Decodable>(forKey key: String, as type: Type.Type) -> Type? {
        guard let data = mmkv.data(forKey: key) else {
            return nil
        }
        return try? jsonDecoder.decode(type, from: data)
    }
}

extension MMKVHelper {
    private class LogHandler: NSObject, MMKVHandler {
        func mmkvLog(with level: MMKVLogLevel, file: UnsafePointer<CChar>!, line: Int32, func funcname: UnsafePointer<CChar>!, message: String!) {
            let fileName = file != nil ? String(cString: file).components(separatedBy: "/").last ?? "Unknown" : "Unknown"
            let functionStr = funcname != nil ? String(cString: funcname) : "Unknown"
            let logMsg = "<\(fileName):\(line)::\(functionStr)> \(message ?? "")"

            let logger = Logger.mmkv

            switch level {
            case .debug:
                logger.debug("\(logMsg, privacy: .public)")
            case .info:
                logger.info("\(logMsg, privacy: .public)")
            case .warning:
                logger.warning("\(logMsg, privacy: .public)")
            case .error:
                logger.error("\(logMsg, privacy: .public)")
            case .none:
                break
            @unknown default:
                logger.log("\(logMsg, privacy: .public)")
            }
        }

        func onMMKVCRCCheckFail(_ mmapID: String!) -> MMKVRecoverStrategic {
            Logger.mmkv.fault("MMKV CRC Check Failed for ID: \(mmapID ?? "Unknown", privacy: .public). Attempting recovery.")
            SentrySDK.capture(message: "MMKV CRC Check Failed for ID: \(mmapID ?? "Unknown")")
            return .onErrorRecover
        }

        func onMMKVFileLengthError(_ mmapID: String!) -> MMKVRecoverStrategic {
            Logger.mmkv.fault("MMKV File Length Error for ID: \(mmapID ?? "Unknown", privacy: .public). Attempting recovery.")
            SentrySDK.capture(message: "MMKV File Length Error for ID: \(mmapID ?? "Unknown")")
            return .onErrorRecover
        }
    }
}

// MARK: - GlobalVars

extension MMKVHelper {
    var appearance: String {
        get { string(forKey: "GlobalVars.appearance") ?? "system" }
        set { set(forKey: "GlobalVars.appearance", newValue) }
    }

    var isUserAgreementAccepted: Bool {
        get { bool(forKey: "GlobalVars.isUserAgreementAccepted") ?? false }
        set { set(forKey: "GlobalVars.isUserAgreementAccepted", newValue) }
    }

    var hasLaunchedBefore: Bool {
        get { bool(forKey: "GlobalVars.hasLaunchedBefore") ?? false }
        set { set(forKey: "GlobalVars.hasLaunchedBefore", newValue) }
    }

    var isLiveActivityEnabled: Bool {
        get { bool(forKey: "GlobalVars.isLiveActivityEnabled") ?? true }
        set { set(forKey: "GlobalVars.isLiveActivityEnabled", newValue) }
    }

    var isWebVPNModeEnabled: Bool {
        get { bool(forKey: "GlobalVars.isWebVPNModeEnabled") ?? false }
        set { set(forKey: "GlobalVars.isWebVPNModeEnabled", newValue) }
    }

    var isNotificationEnabled: Bool {
        get { bool(forKey: "GlobalVars.isNotificationEnabled") ?? true }
        set { set(forKey: "GlobalVars.isNotificationEnabled", newValue) }
    }

    var isBackgroundTaskEnabled: Bool {
        get { bool(forKey: "GlobalVars.isBackgroundTaskEnabled") ?? false }
        set { set(forKey: "GlobalVars.isBackgroundTaskEnabled", newValue) }
    }

    var userId: String? {
        get { string(forKey: "GlobalVars.userId") }
        set {
            if let value = newValue {
                set(forKey: "GlobalVars.userId", value)
            } else {
                removeValue(forKey: "GlobalVars.userId")
            }
        }
    }

    var hasCleanedUpDuplicateElectricityRecords: Bool {
        get { bool(forKey: "GlobalVars.hasCleanedUpDuplicateElectricityRecords") ?? false }
        set { set(forKey: "GlobalVars.hasCleanedUpDuplicateElectricityRecords", newValue) }
    }
}

// MARK: - Cached

extension MMKVHelper {
    var courseGradesCache: Cached<[EduHelper.CourseGrade]>? {
        get { object(forKey: "Cached.courseGradesCache", as: Cached<[EduHelper.CourseGrade]>.self) }
        set { set(forKey: "Cached.courseGradesCache", newValue) }
    }

    var urgentCoursesCache: Cached<UrgentCoursesData>? {
        get { object(forKey: "Cached.urgentCoursesCache", as: Cached<UrgentCoursesData>.self) }
        set { set(forKey: "Cached.urgentCoursesCache", newValue) }
    }

    var examSchedulesCache: Cached<[EduHelper.Exam]>? {
        get { object(forKey: "Cached.examSchedulesCache", as: Cached<[EduHelper.Exam]>.self) }
        set { set(forKey: "Cached.examSchedulesCache", newValue) }
    }

    var courseScheduleCache: Cached<CourseScheduleData>? {
        get { object(forKey: "Cached.courseScheduleCache", as: Cached<CourseScheduleData>.self) }
        set { set(forKey: "Cached.courseScheduleCache", newValue) }
    }

    var physicsExperimentScheduleCache: Cached<[PhysicsExperimentHelper.Course]>? {
        get { object(forKey: "Cached.physicsExperimentScheduleCache", as: Cached<[PhysicsExperimentHelper.Course]>.self) }
        set { set(forKey: "Cached.physicsExperimentScheduleCache", newValue) }
    }
}

// MARK: - CampusMap

extension MMKVHelper {
    var selectedCampus: CampusCardHelper.Campus? {
        get {
            guard let rawValue = string(forKey: "CampusMap.selectedCampus") else { return nil }
            return CampusCardHelper.Campus(rawValue: rawValue)
        }
        set {
            if let value = newValue {
                set(forKey: "CampusMap.selectedCampus", value.rawValue)
            } else {
                removeValue(forKey: "CampusMap.selectedCampus")
            }
        }
    }
}
