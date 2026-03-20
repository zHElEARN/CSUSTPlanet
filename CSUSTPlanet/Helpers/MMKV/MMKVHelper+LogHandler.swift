//
//  MMKVHelper+LogHandler.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import Foundation
import OSLog
import Sentry

#if canImport(MMKV)
import MMKV
#elseif canImport(MMKVAppExtension)
import MMKVAppExtension
#endif

extension MMKVHelper {
    class LogHandler: NSObject, MMKVHandler {
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
