//
//  MMKVHelper+LogHandler.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import Foundation
import OSLog

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

            switch level {
            case .debug:
                Logger.mmkv.debug("\(logMsg, privacy: .public)")
            case .info:
                Logger.mmkv.info("\(logMsg, privacy: .public)")
            case .warning:
                Logger.mmkv.warning("\(logMsg, privacy: .public)")
            case .error:
                Logger.mmkv.error("\(logMsg, privacy: .public)")
            case .none:
                break
            @unknown default:
                Logger.mmkv.log("\(logMsg, privacy: .public)")
            }
        }

        func onMMKVCRCCheckFail(_ mmapID: String!) -> MMKVRecoverStrategic {
            Logger.mmkv.fault("MMKV CRC Check Failed for ID: \(mmapID ?? "Unknown", privacy: .public). Attempting recovery.")
            return .onErrorRecover
        }

        func onMMKVFileLengthError(_ mmapID: String!) -> MMKVRecoverStrategic {
            Logger.mmkv.fault("MMKV File Length Error for ID: \(mmapID ?? "Unknown", privacy: .public). Attempting recovery.")
            return .onErrorRecover
        }
    }
}
