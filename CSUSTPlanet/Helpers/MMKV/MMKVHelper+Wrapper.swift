//
//  MMKVHelper+Wrapper.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import Foundation

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

// MARK: - Conformances

extension String: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> String? { helper.string(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Bool: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Bool? { helper.bool(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Int: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Int? { helper.int(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Double: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Double? { helper.double(forKey: key) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Array: MMKVValueType where Element: Codable {
    static func read(from helper: MMKVHelper, key: String) -> Array? { return helper.object(forKey: key, as: Self.self) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Dictionary: MMKVValueType where Key == String, Value: Codable {
    static func read(from helper: MMKVHelper, key: String) -> Dictionary? { return helper.object(forKey: key, as: Self.self) }
    func write(to helper: MMKVHelper, key: String) { helper.set(forKey: key, self) }
}

extension Date: MMKVValueType {
    static func read(from helper: MMKVHelper, key: String) -> Date? {
        guard let timeInterval = helper.double(forKey: key) else { return nil }
        return Date(timeIntervalSince1970: timeInterval)
    }
    func write(to helper: MMKVHelper, key: String) {
        helper.set(forKey: key, self.timeIntervalSince1970)
    }
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
