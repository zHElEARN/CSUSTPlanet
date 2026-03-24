//
//  DebugToolsView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/24.
//

#if DEBUG
import SwiftUI

struct DebugToolsView: View {
    var body: some View {
        Form {
            Section("存储") {
                NavigationLink(destination: MMKVDebugViewerView()) {
                    Label("MMKV查看器", systemImage: "internaldrive")
                }
                NavigationLink(destination: KeychainDebugViewerView()) {
                    Label("Keychain查看器", systemImage: "key")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("调试工具")
    }
}
#endif
