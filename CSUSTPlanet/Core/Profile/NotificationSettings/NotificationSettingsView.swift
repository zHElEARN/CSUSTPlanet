//
//  NotificationSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/11.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct NotificationSettingsView: View {
    let isLiveActivityEnabled = Binding(
        get: { NotificationManager.shared.isLiveActivityEnabled },
        set: { newValue in
            NotificationManager.shared.isLiveActivityEnabled = newValue
            #if os(iOS)
            ActivityHelper.shared.autoUpdateActivity()
            #endif
        }
    )

    let isNotificationEnabled = Binding(
        get: { NotificationManager.shared.isNotificationEnabled },
        set: { newValue in
            NotificationManager.shared.isNotificationEnabled = newValue
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
        #if os(iOS)
        if let url = URL(string: UIApplication.openNotificationSettingsURLString),
            UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url)
        }

        #elseif os(macOS)
        let settingsURL = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        if let url = URL(string: settingsURL) {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}
