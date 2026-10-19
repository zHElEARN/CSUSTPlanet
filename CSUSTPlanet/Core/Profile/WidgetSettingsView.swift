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
    @State private var isAssignmentsAutoRefreshEnabled = MMKVHelper.WidgetSettings.Assignments.isAutoRefresh
    @State private var assignmentsRefreshFrequency = MMKVHelper.WidgetSettings.Assignments.refreshFrequency

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
                Toggle("自动刷新", isOn: $isAssignmentsAutoRefreshEnabled.withAnimation())
                if isAssignmentsAutoRefreshEnabled {
                    Picker("刷新频率", selection: $assignmentsRefreshFrequency) {
                        ForEach(1..<7) { frequency in
                            Text("\(frequency) 小时").tag(frequency)
                        }
                    }
                }
            } header: {
                Text("作业小组件")
            }
            .onChange(of: isAssignmentsAutoRefreshEnabled) { _, newValue in
                MMKVHelper.WidgetSettings.Assignments.isAutoRefresh = newValue
            }
            .onChange(of: assignmentsRefreshFrequency) { _, newValue in
                MMKVHelper.WidgetSettings.Assignments.refreshFrequency = newValue
            }
        }
        .formStyle(.grouped)
        .navigationTitle("小组件设置")
    }
}
