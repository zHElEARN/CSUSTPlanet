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

    @MMKVStorage(key: "GlobalVars.isNotificationEnabled", defaultValue: true)
    var isNotificationEnabled: Bool

    @MMKVStorage(key: "GlobalVars.isBackgroundTaskEnabled", defaultValue: false)
    var isBackgroundTaskEnabled: Bool

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
    fileprivate func set(forKey key: String, _ value: String) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Int) {
        mmkv.set(Int64(value), forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Bool) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Float) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Double) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set(forKey key: String, _ value: Data) {
        mmkv.set(value, forKey: key)
    }

    fileprivate func set<Type: Encodable>(forKey key: String, _ value: Type) {
        if let data = try? jsonEncoder.encode(value) {
            mmkv.set(data, forKey: key)
        }
    }
}

// MARK: - Getters

extension MMKVHelper {
    fileprivate func string(forKey key: String) -> String? {
        mmkv.string(forKey: key)
    }

    fileprivate func int(forKey key: String) -> Int? {
        if mmkv.contains(key: key) {
            return Int(mmkv.int64(forKey: key))
        }
        return nil
    }

    fileprivate func bool(forKey key: String) -> Bool? {
        if mmkv.contains(key: key) {
            return mmkv.bool(forKey: key)
        }
        return nil
    }

    fileprivate func float(forKey key: String) -> Float? {
        if mmkv.contains(key: key) {
            return mmkv.float(forKey: key)
        }
        return nil
    }

    fileprivate func double(forKey key: String) -> Double? {
        if mmkv.contains(key: key) {
            return mmkv.double(forKey: key)
        }
        return nil
    }

    fileprivate func data(forKey key: String) -> Data? {
        return mmkv.data(forKey: key)
    }

    fileprivate func object<Type: Decodable>(forKey key: String, as type: Type.Type) -> Type? {
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

// MARK: - Property Wrapper

protocol MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Self?
    func write(to helper: MMKVHelper, key: String)
}

@propertyWrapper
struct MMKVStorage<T: MMKVValueType> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get { T.read(from: MMKVHelper.shared, key: key) ?? defaultValue }
        set { newValue.write(to: MMKVHelper.shared, key: key) }
    }
}

@propertyWrapper
struct MMKVOptionalStorage<T: MMKVValueType> {
    let key: String

    var wrappedValue: T? {
        get { T.read(from: MMKVHelper.shared, key: key) }
        set {
            if let value = newValue {
                value.write(to: MMKVHelper.shared, key: key)
            } else {
                MMKVHelper.shared.removeValue(forKey: key)
            }
        }
    }
}

extension String: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> String? { helper.string(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Bool: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Bool? { helper.bool(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Cached: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Cached? { helper.object(forKey: key, as: Self.self) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension CampusCardHelper.Campus: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Self? {
        guard let rawValue = helper.string(forKey: key) else { return nil }
        return Self(rawValue: rawValue)
    }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self.rawValue) }
}
