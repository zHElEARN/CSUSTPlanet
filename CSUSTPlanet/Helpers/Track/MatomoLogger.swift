//
//  MatomoLogger.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/5/14.
//

import OSLog

import enum MatomoTracker.LogLevel
import protocol MatomoTracker.Logger

final class MatomoLogger: MatomoTracker.Logger {
    private let logger = os.Logger.trackHelper
    private let minLevel: LogLevel

    init(minLevel: LogLevel) {
        self.minLevel = minLevel
    }

    func log(_ message: @autoclosure () -> String, with level: LogLevel, file: String, function: String, line: Int) {
        guard level.rawValue >= minLevel.rawValue else { return }

        let fileName = file.components(separatedBy: "/").last ?? file
        let logMessage = "<\(fileName):\(line)::\(function)> \(message())"

        switch level {
        case .verbose, .debug:
            logger.debug("\(logMessage, privacy: .public)")
        case .info:
            logger.info("\(logMessage, privacy: .public)")
        case .warning:
            logger.warning("\(logMessage, privacy: .public)")
        case .error:
            logger.error("\(logMessage, privacy: .public)")
        }
    }
}
