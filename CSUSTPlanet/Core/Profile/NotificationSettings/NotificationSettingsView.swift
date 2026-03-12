//
//  NotificationSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/11.
//

import SwiftUI

struct NotificationSettingsView: View {
    let isLiveActivityEnabled = Binding(
        get: { GlobalManager.shared.isLiveActivityEnabled },
        set: { newValue in
            GlobalManager.shared.isLiveActivityEnabled = newValue
            #if os(iOS)
            ActivityHelper.shared.autoUpdateActivity()
            #endif
        }
    )

    let isNotificationEnabled = Binding(
        get: { GlobalManager.shared.isNotificationEnabled },
        set: { newValue in
            GlobalManager.shared.isNotificationEnabled = newValue
            #if os(iOS)
            NotificationManager.shared.toggle()
            #endif
        }
    )

    var body: some View {
        Form {
            Button(action: { openAppNotificationSettings() }) {
                Label("前往系统通知设置", systemImage: "arrow.right.circle")
            }

            Section {
                Toggle(isOn: isLiveActivityEnabled) {
                    Text("启用实时活动/灵动岛")
                }
            } header: {
                Text("实时活动/灵动岛")
            } footer: {
                Text("实时活动/灵动岛将会显示：上课前20分钟、上课中和下课后5分钟的课程状态")
            }

            Section {
                Toggle(isOn: isNotificationEnabled) {
                    Text("开启通知")
                }
            } header: {
                Text("信息通知")
            } footer: {
                Text("用于宿舍电量定时查询提醒通知")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("通知设置")
        .trackView("NotificationSettings")
    }

    private func openAppNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
