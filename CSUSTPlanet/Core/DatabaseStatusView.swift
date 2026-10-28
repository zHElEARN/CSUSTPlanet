//
//  DatabaseStatusView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/28.
//

import SwiftUI

struct DatabaseStatusView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var degradedMessage: String? = nil

    var body: some View {
        Group {
            switch DatabaseManager.shared.status {
            case .failed(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.yellow)

                    Text("数据库异常")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("数据库初始化失败：\(message)\n\n请尝试强制关闭 App 后重新打开；若仍然异常，请卸载后重新安装。\n\n如果问题仍然存在，请联系开发者。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let emailURL = URL(string: "mailto:developer@zhelearn.com") {
                        Link("联系邮箱：developer@zhelearn.com", destination: emailURL)
                    }

                    Button("复制错误信息") {
                        guard !message.isEmpty else { return }
                        #if os(iOS)
                        PlatformPasteboard.general.string = message
                        #elseif os(macOS)
                        PlatformPasteboard.general.clearContents()
                        PlatformPasteboard.general.setString(message, forType: .string)
                        #endif
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            case .ready, .degraded:
                content()
            }
        }
        .onChange(of: DatabaseManager.shared.status, initial: true) { _, status in
            if case .degraded(let message) = status {
                degradedMessage = message
            }
        }
        .alert("数据库异常", item: $degradedMessage) { _ in
            Button("好", role: .cancel) {}
        } message: { message in
            Text("数据库初始化失败：\(message)\n\n本次使用临时数据运行，产生的改动不会被保存。请尝试强制关闭 App 后重新打开；若仍然异常，请卸载后重新安装。")
        }
    }
}
