//
//  AboutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

struct AboutView: View {
    @StateObject private var viewModel = AboutViewModel()

    var body: some View {
        Form {
            if let aboutMarkdown = viewModel.aboutMarkdown {
                Markdown(aboutMarkdown)
            } else {
                Text("无法加载关于信息")
            }

            Section("应用信息") {
                InfoRow(label: "版本号", value: viewModel.appVersion)
                InfoRow(label: "构建号", value: viewModel.buildNumber)
                InfoRow(label: "运行环境", value: viewModel.environment)
            }

            #if DEBUG
                Section("Debug") {
                    Button(action: { viewModel.generateMockData() }) {
                        Label("生成模拟数据", systemImage: "plus.circle.fill").foregroundColor(.green)
                    }

                    Button(action: { viewModel.clearAllSwiftData() }) {
                        Label("清除所有SwiftData数据", systemImage: "trash").foregroundColor(.red)
                    }

                    Button(action: { viewModel.clearAllMMKVData() }) {
                        Label("清除所有MMKV数据", systemImage: "trash").foregroundColor(.red)
                    }

                    Button(action: { viewModel.clearAllKeychainData() }) {
                        Label("清除所有Keychain数据", systemImage: "trash").foregroundColor(.red)
                    }

                    Button(action: { viewModel.showFlexExplorer() }) {
                        Label("Flipboard Explorer", systemImage: "ladybug.fill").foregroundColor(.blue)
                    }
                }
            #endif
        }
        .background(Color(.systemBackground))
        .navigationTitle("关于")
        .trackView("About")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
