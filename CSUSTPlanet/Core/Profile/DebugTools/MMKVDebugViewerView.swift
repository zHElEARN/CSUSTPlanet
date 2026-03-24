//
//  MMKVDebugViewerView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/24.
//

#if DEBUG
import SwiftUI

struct MMKVDebugViewerView: View {
    @State private var entries: [MMKVHelper.DebugEntry] = []
    @State private var expandedKeys: Set<String> = []

    var body: some View {
        List {
            if entries.isEmpty {
                Text("暂无MMKV数据")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedKeys.contains(entry.key) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedKeys.insert(entry.key)
                                } else {
                                    expandedKeys.remove(entry.key)
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
        .navigationTitle("MMKV查看器")
        .toolbar {
            Button(action: loadEntries) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
        }
        .task { loadEntries() }
    }

    private func loadEntries() {
        entries = MMKVHelper.shared.debugEntries()
        expandedKeys.removeAll()
    }
}

extension MMKVHelper {
    struct DebugEntry: Identifiable {
        let key: String
        let value: String

        var id: String { key }
    }

    func debugEntries() -> [DebugEntry] {
        let keys = mmkv.allKeys().compactMap { $0 as? String }
        return keys.sorted().map { key in
            DebugEntry(key: key, value: debugValueString(forKey: key))
        }
    }

    enum MMKVValue {
        case string(String)
        case bool(Bool)
        case int(Int64)
        case float(Double)
        case date(Date)
        case data(Data)
        case unknown
    }

    private func debugValueString(forKey key: String) -> String {
        switch guessValue(forKey: key) {
        case .string(let value):
            return value
        case .bool(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .float(let value):
            return String(value)
        case .date(let value):
            return value.ISO8601Format()
        case .data(let value):
            return debugString(from: value)
        case .unknown:
            return "unknown"
        }
    }

    private func debugString(from data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data),
            let prettyJSONData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
            let prettyJSONString = String(data: prettyJSONData, encoding: .utf8)
        {
            return prettyJSONString
        }

        if let utf8String = String(data: data, encoding: .utf8) {
            return utf8String
        }

        return "Data(\(data.count) bytes)"
    }

    private func guessValue(forKey key: String) -> MMKVValue {
        guard mmkv.contains(key: key) else {
            return .unknown
        }

        if let string = mmkv.string(forKey: key), !string.isEmpty {
            return .string(string)
        }

        if let date = mmkv.date(forKey: key) {
            return .date(date)
        }

        let intValue = mmkv.int64(forKey: key)
        if intValue == 0 || intValue == 1 {
            return .bool(mmkv.bool(forKey: key))
        }
        if intValue != 0 {
            return .int(intValue)
        }

        let doubleValue = mmkv.double(forKey: key)
        if doubleValue != 0 {
            return .float(doubleValue)
        }

        if let data = mmkv.data(forKey: key) {
            return .data(data)
        }

        return .unknown
    }
}
#endif
