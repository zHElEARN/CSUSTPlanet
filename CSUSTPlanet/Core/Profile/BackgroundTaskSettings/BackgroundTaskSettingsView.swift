//
//  BackgroundTaskSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/12.
//

import SwiftUI

struct BackgroundTaskSettingsView: View {
    @Environment(GlobalManager.self) var globalManager

    var body: some View {
        @Bindable var bindableGlobalManager = globalManager

        Form {
            Section {
                Toggle(isOn: $bindableGlobalManager.isBackgroundTaskEnabled) {
                    Text("开启后台任务")
                }
            } header: {
                Text("后台任务")
            } footer: {
                Text("开启后应用可以在后台定期运行相关操作（后台任务受系统调度），几乎无电量影响")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("后台任务设置")
        .trackView("BackgroundTaskSettingsV")
    }
}
