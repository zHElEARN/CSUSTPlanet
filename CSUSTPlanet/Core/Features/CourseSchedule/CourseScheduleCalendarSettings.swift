//
//  CourseScheduleCalendarSettings.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

struct CourseScheduleCalendarSettings: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isFirstReminderEnabled: Bool = true
    @State private var firstReminderOffset: CourseScheduleReminderOffset = .tenMinutes
    @State private var isSecondReminderEnabled: Bool = false
    @State private var secondReminderOffset: CourseScheduleReminderOffset = .atTime
    @State private var isChoosingAccount = false
    @State private var didExport = false

    let onAdd: (String, [TimeInterval]) async throws -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("开启提醒", isOn: $isFirstReminderEnabled.withAnimation())
                    if isFirstReminderEnabled {
                        reminderPicker(title: "提醒时间", selection: $firstReminderOffset)
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text("作为你的主要上课提醒。可以设置为你需要出门通勤或做课前准备的时间。")
                }

                Section {
                    Toggle("开启额外提醒", isOn: $isSecondReminderEnabled.withAnimation())
                    if isSecondReminderEnabled {
                        reminderPicker(title: "额外提醒时间", selection: $secondReminderOffset)
                    }
                } header: {
                    Text("额外提醒")
                } footer: {
                    Text("你也可以设置两个不同的提醒时间，一个用于预留充足的准备时间，另一个用于临近上课时的最终提醒。")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("添加课表到系统日历")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { isChoosingAccount = true }
                        .disabled(hasDuplicateReminders)
                }
            }
        }
        .sheet(
            isPresented: $isChoosingAccount,
            onDismiss: {
                if didExport { dismiss() }
            }
        ) {
            CalendarExportSheet { accountID in
                try await onAdd(accountID, alarmRelativeOffsets)
                didExport = true
            }
        }
    }

    private var hasDuplicateReminders: Bool {
        isFirstReminderEnabled && isSecondReminderEnabled && firstReminderOffset == secondReminderOffset
    }

    private var alarmRelativeOffsets: [TimeInterval] {
        var offsets: [TimeInterval] = []
        if isFirstReminderEnabled {
            offsets.append(-firstReminderOffset.rawValue)
        }
        if isSecondReminderEnabled {
            offsets.append(-secondReminderOffset.rawValue)
        }
        return offsets
    }

    @ViewBuilder
    private func reminderPicker(title: String, selection: Binding<CourseScheduleReminderOffset>) -> some View {
        Picker(title, selection: selection) {
            ForEach(CourseScheduleReminderOffset.allCases) { offset in
                Text(offset.title).tag(offset)
            }
        }
        .pickerStyle(.menu)
    }
}
