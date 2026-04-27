//
//  FormRow.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/15.
//

import SwiftUI

struct FormRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label) {
            Text(value)
        }
        .contentShape(.rect)
        .contextMenu {
            Button(action: { copyToClipboard(value) }) {
                Label("复制内容", systemImage: "doc")
            }
            Button(action: { copyToClipboard("\(label): \(value)") }) {
                Label("复制整行", systemImage: "doc.on.doc")
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
