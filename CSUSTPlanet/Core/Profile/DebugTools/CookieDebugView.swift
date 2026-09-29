//
//  CookieDebugView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/29.
//

#if DEBUG
import Foundation
import SwiftUI

struct CookieDebugView: View {
    @State private var exportPayload: String = ""
    @State private var exportCookieCount: Int = 0
    @State private var exportByteCount: Int = 0
    @State private var importText: String = ""
    @State private var alertItem: DebugAlertItem?

    var body: some View {
        Form {
            Section {
                LabeledContent("导出载荷") {
                    Text("共 \(exportCookieCount) 条 · \(exportByteCount.formatted(.byteCount(style: .file)))")
                        .monospacedDigit()
                }
                Button(action: copyExportPayload) {
                    Label("导出并复制", systemImage: "doc.on.doc")
                }
            } header: {
                Text("导出")
            } footer: {
                Text("导出内容为 Cookie 归档数据的 Base64 文本，仅用于在另一台设备的本页面导入。")
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if importText.isEmpty {
                        Text("粘贴 Base64 载荷")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $importText)
                        .font(.caption.monospaced())
                        .frame(minHeight: 160)
                        .autocorrectionDisabled()
                }
                Button(action: importPayload) {
                    Label("导入", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("导入")
            } footer: {
                Text("导入会先清空当前全部 Cookie，再写入粘贴的载荷并立即持久化，重启 App 后生效。")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Cookie管理")
        .toolbar {
            Button(action: refreshExportPayload) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
        }
        .task { refreshExportPayload() }
        .alert(
            alertItem?.title ?? "",
            isPresented: Binding(
                get: { alertItem != nil },
                set: { if !$0 { alertItem = nil } }
            ),
            presenting: alertItem
        ) { _ in
            Button("确定", role: .cancel) {}
        } message: { item in
            Text(item.message)
        }
    }

    private func refreshExportPayload() {
        let cookies = CookieHelper.shared.currentCookies
        exportCookieCount = cookies.count

        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: true) else {
            exportPayload = ""
            exportByteCount = 0
            return
        }

        exportPayload = data.base64EncodedString()
        exportByteCount = data.count
    }

    private func copyExportPayload() {
        guard !exportPayload.isEmpty else {
            alertItem = DebugAlertItem(title: "导出失败", message: "无法归档当前 Cookie 数据。")
            return
        }

        copyToPasteboard(exportPayload)

        if exportCookieCount == 0 {
            alertItem = DebugAlertItem(title: "已复制", message: "当前没有 Cookie，已复制空载荷。")
        } else {
            alertItem = DebugAlertItem(title: "已复制", message: "已复制 \(exportCookieCount) 条 Cookie 的载荷。")
        }
    }

    private func importPayload() {
        let base64 = importText.filter { !$0.isWhitespace }
        guard !base64.isEmpty else {
            alertItem = DebugAlertItem(title: "导入失败", message: "请输入要导入的载荷。")
            return
        }

        guard let data = Data(base64Encoded: base64) else {
            alertItem = DebugAlertItem(title: "导入失败", message: "载荷不是合法的 Base64 文本。")
            return
        }

        guard let cookies = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie] else {
            alertItem = DebugAlertItem(title: "导入失败", message: "载荷无法解析为 Cookie 数据。")
            return
        }

        CookieHelper.shared.clearCookies()
        CookieHelper.shared.updateCookies(cookies)
        CookieHelper.shared.save()

        importText = ""
        refreshExportPayload()
        alertItem = DebugAlertItem(title: "导入成功", message: "已写入 \(cookies.count) 条 Cookie，重启 App 后生效。")
    }

    private func copyToPasteboard(_ text: String) {
        #if os(iOS)
        PlatformPasteboard.general.string = text
        #elseif os(macOS)
        PlatformPasteboard.general.clearContents()
        PlatformPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

private struct DebugAlertItem {
    let title: String
    let message: String
}
#endif
