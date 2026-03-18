//
//  BackgroundTaskSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/12.
//

#if os(iOS)
import SwiftUI

struct BackgroundTaskSettingsView: View {
    @Bindable var helper = BackgroundTaskHelper.shared

    var body: some View {

        Form {
            Section {
                let isEnabledBinding = Binding(
                    get: { helper.isEnabled },
                    set: { newValue in withAnimation { helper.isEnabled = newValue } }
                )

                Toggle(isOn: isEnabledBinding) {
                    Text("后台任务总开关")
                }

                if helper.isEnabled {
                    Picker("更新频率", selection: $helper.interval) {
                        ForEach(helper.availableIntervals, id: \.self) { interval in
                            Text(formatInterval(interval)).tag(interval)
                        }
                    }
                }
            } header: {
                Text("后台任务")
            } footer: {
                Text("开启后应用可以在后台定期运行相关操作，后台任务受系统调度，更新频率可能不准确，无电量续航影响。需要开启总开关才能以下任务才会生效")
            }

            ForEach(helper.tasks, id: \.identifier) { task in
                let toggleBinding = Binding(
                    get: { helper.enabledTaskIdentifiers.contains(task.identifier) },
                    set: { _ in helper.toggleTask(task) }
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
#endif
