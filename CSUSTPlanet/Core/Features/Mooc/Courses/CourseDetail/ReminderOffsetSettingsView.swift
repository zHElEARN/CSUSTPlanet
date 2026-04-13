//
//  ReminderOffsetSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/17.
//

import SwiftUI

struct ReminderOffsetSettingsView: View {
    @Binding var isPresented: Bool

    @State private var selectedHourOffset: Int = 2
    @State private var selectedMinuteOffset: Int = 0

    var onConfirm: (Int, Int) -> Void

    private let hours = Array(0...72)
    private let minutes = Array(0...59)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("小时", selection: $selectedHourOffset) {
                        ForEach(hours, id: \.self) { hour in
                            Text("\(hour)小时").tag(hour)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("分钟", selection: $selectedMinuteOffset) {
                        ForEach(minutes, id: \.self) { minute in
                            Text("\(minute)分钟").tag(minute)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("提醒时间")
                } footer: {
                    Text("系统会在作业截止时间前提醒您。提醒将添加到系统提醒事项中，并且只会添加未提交的作业。")
                }

                Section {
                    LabeledContent("提醒预览") {
                        Text("提前 \(formatOffset()) 提醒")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("作业提醒设置")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") {
                        isPresented = false
                        onConfirm(selectedHourOffset, selectedMinuteOffset)
                    }
                }
            }
        }
    }

    private func formatOffset() -> String {
        var components: [String] = []

        if selectedHourOffset > 0 {
            components.append("\(selectedHourOffset)小时")
        }

        if selectedMinuteOffset > 0 {
            components.append("\(selectedMinuteOffset)分钟")
        }

        if components.isEmpty {
            return "截止时间"
        }

        return components.joined(separator: " ")
    }
}

#Preview {
    NavigationStack {
        ReminderOffsetSettingsView(
            isPresented: .constant(true),
            onConfirm: { _, _ in }
        )
    }
}
