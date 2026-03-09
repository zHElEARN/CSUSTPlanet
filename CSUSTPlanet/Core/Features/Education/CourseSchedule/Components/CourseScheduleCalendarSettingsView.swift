//
//  CourseScheduleCalendarSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/9.
//

import SwiftUI

enum CalendarReminderOffset: TimeInterval, CaseIterable, Identifiable {
    case atTime = 0
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200
    case oneDay = 86400
    case twoDays = 172800
    case oneWeek = 604800

    var id: TimeInterval { rawValue }

    var title: String {
        switch self {
        case .atTime: return "事件发生时"
        case .fiveMinutes: return "提前 5 分钟"
        case .tenMinutes: return "提前 10 分钟"
        case .fifteenMinutes: return "提前 15 分钟"
        case .thirtyMinutes: return "提前 30 分钟"
        case .oneHour: return "提前 1 小时"
        case .twoHours: return "提前 2 小时"
        case .oneDay: return "提前 1 天"
        case .twoDays: return "提前 2 天"
        case .oneWeek: return "提前 1 周"
        }
    }
}

struct CourseScheduleCalendarSettingsView: View {
    @Binding var isPresented: Bool

    @State private var firstReminderOffset: CalendarReminderOffset = .tenMinutes
    @State private var isFirstReminderEnabled: Bool = true

    @State private var secondReminderOffset: CalendarReminderOffset = .atTime
    @State private var isSecondReminderEnabled: Bool = false

    var onConfirm:
        (
            _ firstReminderOffset: TimeInterval, _ isFirstEnabled: Bool,
            _ secondReminderOffset: TimeInterval, _ isSecondEnabled: Bool
        ) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("开启第一提醒", isOn: $isFirstReminderEnabled)

                    if isFirstReminderEnabled {
                        reminderPicker(title: "第一提醒时间", selection: $firstReminderOffset)
                    }
                } header: {
                    Text("第一提醒")
                }

                Section {
                    Toggle("开启第二提醒", isOn: $isSecondReminderEnabled)

                    if isSecondReminderEnabled {
                        reminderPicker(title: "第二提醒时间", selection: $secondReminderOffset)
                    }
                } header: {
                    Text("第二提醒")
                }
            }
            .navigationTitle("添加到系统日历")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认添加") {
                        isPresented = false
                        onConfirm(
                            firstReminderOffset.rawValue, isFirstReminderEnabled,
                            secondReminderOffset.rawValue, isSecondReminderEnabled
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reminderPicker(title: String, selection: Binding<CalendarReminderOffset>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Picker(title, selection: selection) {
                ForEach(CalendarReminderOffset.allCases) { offset in
                    Text(offset.title).tag(offset)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

#Preview {
    CourseScheduleCalendarSettingsView(isPresented: .constant(true)) { _, _, _, _ in }
}
