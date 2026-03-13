//
//  BackgroundTaskSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/12.
//

import SwiftUI

struct BackgroundTaskSettingsView: View {
    @Environment(GlobalManager.self) var globalManager
    var backgroundTaskHelper = BackgroundTaskHelper.shared

    var body: some View {
        @Bindable var bindableGlobalManager = globalManager

        Form {
            Section {
                let intervalBinding = Binding(
                    get: { backgroundTaskHelper.interval },
                    set: { newValue in backgroundTaskHelper.interval = newValue }
                )

                Toggle(isOn: $bindableGlobalManager.isBackgroundTaskEnabled) {
                    Text("后台任务总开关")
                }

                if bindableGlobalManager.isBackgroundTaskEnabled {
                    Picker("更新频率", selection: intervalBinding) {
                        ForEach(backgroundTaskHelper.availableIntervals, id: \.self) { interval in
                            Text(formatInterval(interval)).tag(interval)
                        }
                    }
                }
            } footer: {
                Text("开启后应用可以在后台定期运行相关操作，后台任务受系统调度，更新频率可能不准确，无电量续航影响")
            }

            ForEach(backgroundTaskHelper.tasks, id: \.identifier) { task in
                let isTaskEnabled = backgroundTaskHelper.enabledTaskIdentifiers.contains(task.identifier)

                let toggleBinding = Binding(
                    get: { isTaskEnabled },
                    set: { _ in backgroundTaskHelper.toggleTask(task) }
                )

                Section {
                    Toggle(isOn: toggleBinding) {
                        Text("开启")
                    }
                } header: {
                    Text(task.title)
                } footer: {
                    Text(task.description)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("后台任务设置")
        .trackView("BackgroundTaskSettings")
    }

    private func formatInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 && minutes == 0 {
            return "\(hours) 小时"
        } else if hours > 0 && minutes > 0 {
            return "\(hours) 小时 \(minutes) 分钟"
        } else {
            return "\(minutes) 分钟"
        }
    }
}
