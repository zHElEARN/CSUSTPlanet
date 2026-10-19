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
    #if os(iOS)
    @Bindable var activityManager = ActivityManager.shared
    #endif

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    Text(effectivePermissionStatus.rawValue)
                        .foregroundStyle(notificationPermissionColor)
                } label: {
                    Text("通知权限")
                }

                if effectivePermissionStatus == .requestable {
                    Button(asyncAction: { _ = try? await notificationManager.requestPermission() }) {
                        Text("点击开启通知")
                    }
                } else {
                    Button(action: notificationManager.openAppNotificationSettings) {
                        Text(effectivePermissionStatus == .denied ? "前往系统设置开启通知" : "前往系统设置管理通知")
                    }
                }
            } header: {
                Text("推送通知")
            } footer: {
                Text("开启后，你将能及时收到宿舍电量定时查询等重要提醒。")
            }

            #if os(iOS)
            Section {
                Toggle(isOn: $activityManager.isEnabled) {
                    Text("允许实时活动")
                }
            } header: {
                Text("实时活动与灵动岛")
            } footer: {
                Text("实时活动/灵动岛将会显示：上课前20分钟、上课中和下课后5分钟的课程状态")
            }
            #endif
        }
        .formStyle(.grouped)
        .navigationTitle("通知设置")
    }

    private var effectivePermissionStatus: NotificationPermissionStatus {
        notificationManager.permissionStatus ?? .denied
    }

    private var notificationPermissionColor: Color {
        effectivePermissionStatus == .denied ? .red : .primary
    }
}
