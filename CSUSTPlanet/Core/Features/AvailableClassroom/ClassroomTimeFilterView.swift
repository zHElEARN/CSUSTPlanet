//
//  ClassroomTimeFilterView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/11.
//

import CSUSTKit
import SwiftUI

struct ClassroomTimeFilterView: View {
    @Binding var selectedWeek: Int
    @Binding var selectedDay: DayOfWeek
    @Binding var startSection: Int
    @Binding var endSection: Int
    let weekCount: Int
    let sectionCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            filters
                .navigationTitle("查询时段")
                .inlineToolbarTitle()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { dismiss() }
                    }
                }
        }
    }

    private var filters: some View {
        Form {
            Section("日期") {
                Picker("周次", selection: $selectedWeek.withAnimation()) {
                    ForEach(1...weekCount, id: \.self) { Text("第 \($0) 周").tag($0) }
                }
                Picker("星期", selection: $selectedDay.withAnimation()) {
                    ForEach(ClassroomAvailability.weekdays, id: \.self) { Text($0.chineseLongString).tag($0) }
                }
            }
            Section {
                Picker("开始节次", selection: $startSection.withAnimation()) {
                    ForEach(1...sectionCount, id: \.self) { Text("第 \($0) 节").tag($0) }
                }
                Picker("结束节次", selection: $endSection.withAnimation()) {
                    ForEach(1...sectionCount, id: \.self) { Text("第 \($0) 节").tag($0) }
                }
            } header: {
                Text("节次范围")
            } footer: {
                Text("所选节次内均无课程的教室将显示为空闲。")
            }
        }
        .formStyle(.grouped)
        .pickerStyle(.menu)
    }

}
