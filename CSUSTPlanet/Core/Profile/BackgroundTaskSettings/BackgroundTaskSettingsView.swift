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
    @State private var isNotificationDeniedAlertPresented = false

    var body: some View {
        Form {
            Section {
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
                Text("开启后应用可以在后台定期运行相关操作，后台任务受系统调度，更新频率可能不准确，无电量续航影响。需要开启通知权限并开启总开关才能以下任务才会生效")
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
        .alert("通知权限被拒绝", isPresented: $isNotificationDeniedAlertPresented) {
            Button("取消", role: .cancel) {
                isNotificationDeniedAlertPresented = false
            }
            Button("前往设置") {
                NotificationManager.shared.openAppNotificationSettings()
                isNotificationDeniedAlertPresented = false
            }
        } message: {
            Text("需要开启通知权限以启用后台任务，请前往系统设置开启通知权限。")
        }
    }

    private var isEnabledBinding: Binding<Bool> {
        Binding(
            get: { helper.isEnabled },
            set: { newValue in
                Task { @MainActor in
                    let didSucceed = await helper.setEnabledByUser(newValue)
                    handleToggleResult(isEnabled: newValue, didSucceed: didSucceed)
                }
            }
        )
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

    @MainActor
    private func handleToggleResult(isEnabled: Bool, didSucceed: Bool) {
        guard isEnabled, !didSucceed else { return }
        isNotificationDeniedAlertPresented = true
    }
}
#endif
