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

enum CalendarExportScope: Int, CaseIterable, Identifiable {
    case next1Week = 1
    case next2Weeks = 2
    case next3Weeks = 3
    case next4Weeks = 4
    case next5Weeks = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .next1Week: return "未来 1 周"
        case .next2Weeks: return "未来 2 周"
        case .next3Weeks: return "未来 3 周"
        case .next4Weeks: return "未来 4 周"
        case .next5Weeks: return "未来 5 周"
        }
    }
}

struct CourseScheduleCalendarSettingsView: View {
    @Binding var isPresented: Bool

    @State private var firstReminderOffset: CalendarReminderOffset = .tenMinutes
    @State private var isFirstReminderEnabled: Bool = true

    @State private var secondReminderOffset: CalendarReminderOffset = .atTime
    @State private var isSecondReminderEnabled: Bool = false

    @State private var exportScope: CalendarExportScope = .next1Week
    @State private var isExportScopeLimited: Bool = false

    var onConfirm: (_ firstReminderOffset: TimeInterval?, _ secondReminderOffset: TimeInterval?, _ exportScope: Int?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(
                        "开启提醒",
                        isOn: Binding(
                            get: { isFirstReminderEnabled },
                            set: { value in withAnimation { isFirstReminderEnabled = value } }
                        )
                    )

                    if isFirstReminderEnabled {
                        reminderPicker(title: "提醒时间", selection: $firstReminderOffset)
                    }
                } header: {
                    Text("提醒")
                } footer: {
                    Text("作为你的主要上课提醒。可以设置为你需要出门通勤或做课前准备的时间。")
                }

                Section {
                    Toggle(
                        "开启额外提醒",
                        isOn: Binding(
                            get: { isSecondReminderEnabled },
                            set: { value in withAnimation { isSecondReminderEnabled = value } }
                        )
                    )

                    if isSecondReminderEnabled {
                        reminderPicker(title: "额外提醒时间", selection: $secondReminderOffset)
                    }
                } header: {
                    Text("额外提醒")
                } footer: {
                    Text("你也可以设置两个不同的提醒时间，一个用于预留充足的准备时间，另一个用于临近上课时的最终提醒。")
                }

                Section {
                    Toggle(
                        "限制导出范围",
                        isOn: Binding(
                            get: { isExportScopeLimited },
                            set: { value in withAnimation { isExportScopeLimited = value } }
                        )
                    )

                    if isExportScopeLimited {
                        Picker("导出范围", selection: $exportScope) {
                            ForEach(CalendarExportScope.allCases) { scope in
                                Text(scope.title).tag(scope)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("导出范围")
                } footer: {
                    Text("默认导出本学期所有课程。开启后可限制仅导出未来几周的课程。")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("添加课表到系统日历")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        isPresented = false
                        onConfirm(
                            isFirstReminderEnabled ? firstReminderOffset.rawValue : nil,
                            isSecondReminderEnabled ? secondReminderOffset.rawValue : nil,
                            isExportScopeLimited ? exportScope.rawValue : nil
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reminderPicker(title: String, selection: Binding<CalendarReminderOffset>) -> some View {
        Picker(title, selection: selection) {
            ForEach(CalendarReminderOffset.allCases) { offset in
                Text(offset.title).tag(offset)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    CourseScheduleCalendarSettingsView(isPresented: .constant(true)) { _, _, _ in }
}
