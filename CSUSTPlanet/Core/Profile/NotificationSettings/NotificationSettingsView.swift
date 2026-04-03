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
    @State private var viewModel = NotificationSettingsViewModel()
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

            if !viewModel.scheduledDorms.isEmpty {
                Section {
                    ForEach(viewModel.scheduledDorms) { dorm in
                        scheduledDormRow(dorm)
                    }
                } header: {
                    Text("宿舍电量定时通知")
                } footer: {
                    Text("长按或右滑可快速取消。")
                }
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
        .task { await viewModel.loadInitial() }
        .alert(
            "取消定时通知",
            isPresented: .init(
                get: { viewModel.targetCancelDorm != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissCancelScheduleAlert()
                    }
                }
            )
        ) {
            Button("保留", role: .cancel) {}
            Button("取消定时通知", role: .destructive) {
                Task { await viewModel.confirmCancelSchedule() }
            }
            .disabled(viewModel.isSchedulingDorm)
        } message: {
            if let targetCancelDorm = viewModel.targetCancelDorm {
                Text("确认取消 \(targetCancelDorm.buildingName) \(targetCancelDorm.room) 每天 \(formattedScheduleTime(for: targetCancelDorm)) 的宿舍电量提醒吗？")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("通知设置")
        .errorToast($viewModel.errorToast)
        .trackView("NotificationSettings")
    }

    private var effectivePermissionStatus: NotificationPermissionStatus {
        notificationManager.permissionStatus ?? .denied
    }

    private var notificationPermissionColor: Color {
        effectivePermissionStatus == .denied ? .red : .primary
    }

    private func scheduledDormRow(_ dorm: DormGRDB) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dorm.buildingName) \(dorm.room)")
                    .fontWeight(.medium)

                Text(dorm.campusName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedScheduleTime(for: dorm))
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: { viewModel.presentCancelScheduleAlert(for: dorm) }) {
                Label("取消定时通知", systemImage: "bell.slash").tint(.red)
            }
            .disabled(viewModel.isSchedulingDorm)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: { viewModel.presentCancelScheduleAlert(for: dorm) }) {
                Label("取消通知", systemImage: "bell.slash").tint(.red)
            }
            .disabled(viewModel.isSchedulingDorm)
        }
    }

    private func formattedScheduleTime(for dorm: DormGRDB) -> String {
        String(format: "%02d:%02d", dorm.scheduleHour ?? 20, dorm.scheduleMinute ?? 0)
    }
}
