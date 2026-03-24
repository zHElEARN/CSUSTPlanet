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
    @Bindable var notificationManager = NotificationManager.shared
    @State private var isShowingNotificationSettingsAlert = false

    #if os(iOS)
    @Bindable var activityManager = ActivityManager.shared
    #endif

    private var notificationToggleBinding: Binding<Bool> {
        Binding(
            get: { notificationManager.isNotificationEnabled },
            set: { newValue in
                Task {
                    let result = await notificationManager.setNotificationEnabled(newValue)
                    if result == .requiresSystemSettings {
                        isShowingNotificationSettingsAlert = true
                    }
                }
            }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: notificationToggleBinding) {
                    Text("开启通知")
                }
                .disabled(notificationManager.isHandlingNotificationToggle)

                Button(action: { openAppNotificationSettings() }) {
                    Label("前往系统通知设置", systemImage: "arrow.right.circle")
                }
            } header: {
                Text("信息通知")
            } footer: {
                Text("用于宿舍电量定时查询提醒通知")
            }

            #if os(iOS)
            Section {
                Toggle(isOn: $activityManager.isLiveActivityEnabled) {
                    Text("启用实时活动/灵动岛")
                }
            } header: {
                Text("实时活动/灵动岛")
            } footer: {
                Text("实时活动/灵动岛将会显示：上课前20分钟、上课中和下课后5分钟的课程状态")
            }
            #endif
        }
        .formStyle(.grouped)
        .navigationTitle("通知设置")
        .trackView("NotificationSettings")
        .task {
            await notificationManager.refreshAuthorizationStatus()
        }
        .alert("通知权限未开启", isPresented: $isShowingNotificationSettingsAlert) {
            Button("取消", role: .cancel) {
            }
            Button("前往设置") {
                openAppNotificationSettings()
            }
        } message: {
            Text("请先在系统设置中开启通知权限，然后再回来打开应用内通知开关。")
        }
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
