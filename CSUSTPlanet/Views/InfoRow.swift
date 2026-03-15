//
//  InfoRow.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/29.
//

import SwiftUI

@available(*, deprecated, message: "请迁移使用 FormRow")
struct InfoRow: View {
    init(icon: (String, Color)? = nil, label: String, value: String) {
        self.icon = icon
        self.label = label
        self.value = value
    }
    let icon: (String, Color)?
    let label: String?
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon.0)
                    .frame(width: 20)
                    .foregroundStyle(icon.1)
                VStack(alignment: .leading, spacing: 2) {
                    if let label = label {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
            } else {
                if let label = label {
                    Text(label)
                    Spacer()
                }
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
        .contextMenu {
            Button(action: {
                #if os(iOS)
                UIPasteboard.general.string = value
                #elseif os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(value, forType: .string)
                #endif
            }) {
                Label("复制值", systemImage: "doc.on.doc")
            }
            if let label = label {
                Button(action: {
                    #if os(iOS)
                    UIPasteboard.general.string = "\(label): \(value)"
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString("\(label): \(value)", forType: .string)
                    #endif
                }) {
                    Label("复制全部", systemImage: "doc.on.doc.fill")
                }
            }
        }
    }
}
