//
//  MMKVHelper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2025/10/1.
//

import CSUSTKit
import Foundation
import OSLog

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
}

// MARK: - Methods

extension MMKVHelper {
    func removeValue(forKey key: String) {
        mmkv.removeValue(forKey: key)
    }
}
