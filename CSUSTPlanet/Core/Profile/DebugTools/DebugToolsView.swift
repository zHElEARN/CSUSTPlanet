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
            Section {
                NavigationLink(destination: MockDataGeneratorView()) {
                    Label("模拟数据生成", systemImage: "wand.and.stars")
                }
                NavigationLink(destination: MMKVDebugViewerView()) {
                    Label("MMKV查看器", systemImage: "internaldrive")
                }
                NavigationLink(destination: KeychainDebugViewerView()) {
                    Label("Keychain查看器", systemImage: "key")
                }
                NavigationLink(destination: AppGroupsFileBrowserView()) {
                    Label("AppGroups文件", systemImage: "folder")
                }
                NavigationLink(destination: AppSandboxFileBrowserView()) {
                    Label("App沙箱文件", systemImage: "externaldrive")
                }
                NavigationLink(destination: ConstantsDebugView()) {
                    Label("Constants常量", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: DebugLogViewerView()) {
                    Label("日志查看器", systemImage: "text.alignleft")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("调试工具")
    }
}
#endif
