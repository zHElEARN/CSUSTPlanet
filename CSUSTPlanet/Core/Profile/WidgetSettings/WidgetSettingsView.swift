//
//  WidgetSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/5/15.
//

import SwiftUI

struct WidgetSettingsView: View {
    @State private var isDormElectricityAutoRefreshEnabled = MMKVHelper.WidgetSettings.DormElectricity.isAutoRefresh
    @State private var dormElectricityRefreshFrequency = MMKVHelper.WidgetSettings.DormElectricity.refreshFrequency
    @State private var isGradeAnalysisAutoRefreshEnabled = MMKVHelper.WidgetSettings.GradeAnalysis.isAutoRefresh
    @State private var gradeAnalysisRefreshFrequency = MMKVHelper.WidgetSettings.GradeAnalysis.refreshFrequency
    @State private var isTodoAssignmentsAutoRefreshEnabled = MMKVHelper.WidgetSettings.TodoAssignments.isAutoRefresh
    @State private var todoAssignmentsRefreshFrequency = MMKVHelper.WidgetSettings.TodoAssignments.refreshFrequency

    var body: some View {
        Form {
            Section {
                Toggle("自动刷新", isOn: $isDormElectricityAutoRefreshEnabled.withAnimation())
                if isDormElectricityAutoRefreshEnabled {
                    Picker("刷新频率", selection: $dormElectricityRefreshFrequency) {
                        ForEach(1..<7) { frequency in
                            Text("\(frequency) 小时").tag(frequency)
                        }
                    }
                }
            } header: {
                Text("宿舍电量小组件")
            }
            .onChange(of: isDormElectricityAutoRefreshEnabled) { _, newValue in
                MMKVHelper.WidgetSettings.DormElectricity.isAutoRefresh = newValue
            }
            .onChange(of: dormElectricityRefreshFrequency) { _, newValue in
                MMKVHelper.WidgetSettings.DormElectricity.refreshFrequency = newValue
            }

            Section {
                Toggle("自动刷新", isOn: $isGradeAnalysisAutoRefreshEnabled.withAnimation())
                if isGradeAnalysisAutoRefreshEnabled {
                    Picker("刷新频率", selection: $gradeAnalysisRefreshFrequency) {
                        ForEach(1..<7) { frequency in
                            Text("\(frequency) 小时").tag(frequency)
                        }
                    }
                }
            } header: {
                Text("成绩分析小组件")
            }
            .onChange(of: isGradeAnalysisAutoRefreshEnabled) { _, newValue in
                MMKVHelper.WidgetSettings.GradeAnalysis.isAutoRefresh = newValue
            }
            .onChange(of: gradeAnalysisRefreshFrequency) { _, newValue in
                MMKVHelper.WidgetSettings.GradeAnalysis.refreshFrequency = newValue
            }

            Section {
                Toggle("自动刷新", isOn: $isTodoAssignmentsAutoRefreshEnabled.withAnimation())
                if isTodoAssignmentsAutoRefreshEnabled {
                    Picker("刷新频率", selection: $todoAssignmentsRefreshFrequency) {
                        ForEach(1..<7) { frequency in
                            Text("\(frequency) 小时").tag(frequency)
                        }
                    }
                }
            } header: {
                Text("待提交作业小组件")
            }
            .onChange(of: isTodoAssignmentsAutoRefreshEnabled) { _, newValue in
                MMKVHelper.WidgetSettings.TodoAssignments.isAutoRefresh = newValue
            }
            .onChange(of: todoAssignmentsRefreshFrequency) { _, newValue in
                MMKVHelper.WidgetSettings.TodoAssignments.refreshFrequency = newValue
            }
        }
        .formStyle(.grouped)
        .navigationTitle("小组件设置")
    }
}
