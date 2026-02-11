//
//  KeychainUtil.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/2/8.
//

import Foundation

enum KeychainUtil {
    // MARK: - Core Methods

    static private func set(_ data: Data?, forKey key: String) {
        guard let data = data else {
            delete(forKey: key)
            return
        }
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)
        var newQuery = query
        newQuery[kSecValueData as String] = data
        newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(newQuery as CFDictionary, nil)
    }

    static private func getData(forKey key: String) -> Data? {
        var query = baseQuery(key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        return status == errSecSuccess ? (dataTypeRef as? Data) : nil
    }

    // MARK: - Convenience Methods

    static private func set(_ string: String?, forKey key: String) {
        guard let string = string else {
            delete(forKey: key)
            return
        }
        set(string.data(using: .utf8), forKey: key)
    }

    static private func getString(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static private func delete(forKey key: String) {
        let query = baseQuery(key: key)
        SecItemDelete(query as CFDictionary)
    }

    static func deleteAll() {
        let secClasses: [CFTypeRef] = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for secClass in secClasses {
            let query: [String: Any] = [
                kSecClass as String: secClass,
                kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
                kSecAttrAccessGroup as String: Constants.keychainGroup,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    static private func baseQuery(key: String) -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
        ]
    }
}

// MARK: - Business Properties

extension KeychainUtil {
    static var physicsExperimentUsername: String? {
        get { getString(forKey: "PhysicsExperimentUsername") }
        set { set(newValue, forKey: "PhysicsExperimentUsername") }
    }

    static var physicsExperimentPassword: String? {
        get { getString(forKey: "PhysicsExperimentPassword") }
        set { set(newValue, forKey: "PhysicsExperimentPassword") }
    }

    static var ssoUsername: String? {
        get { getString(forKey: "SSOUsername") }
        set { set(newValue, forKey: "SSOUsername") }
    }

    static var ssoPassword: String? {
        get { getString(forKey: "SSOPassword") }
        set { set(newValue, forKey: "SSOPassword") }
    }

    static var cookies: Data? {
        get { getData(forKey: "Cookies") }
        set { set(newValue, forKey: "Cookies") }
    }
}
