//
//  KeychainDebugViewerView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/24.
//

#if DEBUG
import Security
import SwiftUI

struct KeychainDebugViewerView: View {
    @State private var entries: [KeychainUtil.DebugEntry] = []
    @State private var expandedIDs: Set<String> = []

    var body: some View {
        List {
            if entries.isEmpty {
                Text("暂无Keychain数据")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedIDs.contains(entry.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedIDs.insert(entry.id)
                                } else {
                                    expandedIDs.remove(entry.id)
                                }
                            }
                        ),
                        content: {
                            Text(entry.value)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        },
                        label: {
                            Text(entry.key)
                                .font(.headline)
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                        }
                    )
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Keychain查看器")
        .toolbar {
            Button(action: loadEntries) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
        }
        .task { loadEntries() }
    }

    private func loadEntries() {
        entries = KeychainUtil.debugEntries()
        expandedIDs.removeAll()
    }
}

extension KeychainUtil {
    struct DebugEntry: Identifiable {
        let id: String
        let key: String
        let value: String
    }

    static func debugEntries() -> [DebugEntry] {
        let secClasses: [CFString] = [kSecClassGenericPassword, kSecClassInternetPassword]
        return
            secClasses
            .flatMap { secClass in
                readEntries(for: secClass)
            }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
    }

    private static func readEntries(for secClass: CFString) -> [DebugEntry] {
        let query: [String: Any] = [
            kSecClass as String: secClass,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecAttrAccessGroup as String: Constants.keychainGroup,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return [] }

        let rawItems = result as? [[String: Any]] ?? []
        let classPrefix = secClass == kSecClassInternetPassword ? "internetPassword" : "genericPassword"

        return rawItems.enumerated().map { index, item in
            let account = (item[kSecAttrAccount as String] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let service = (item[kSecAttrService as String] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseKey = [classPrefix, service, account]
                .compactMap { value in
                    guard let value, !value.isEmpty else { return nil }
                    return value
                }
                .joined(separator: " · ")

            let key = baseKey.isEmpty ? "\(classPrefix) · item-\(index + 1)" : baseKey
            let value = debugValueString(from: item[kSecValueData as String] as? Data)
            return DebugEntry(id: "\(key)#\(index)", key: key, value: value)
        }
    }

    private static func debugValueString(from data: Data?) -> String {
        guard let data else { return "<empty>" }

        if data.isEmpty {
            return "<empty>"
        }

        if let object = try? JSONSerialization.jsonObject(with: data),
            let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let prettyJSONString = String(data: prettyData, encoding: .utf8)
        {
            return prettyJSONString
        }

        if let utf8String = String(data: data, encoding: .utf8) {
            return utf8String
        }

        return "Data(\(data.count) bytes)"
    }
}
#endif
