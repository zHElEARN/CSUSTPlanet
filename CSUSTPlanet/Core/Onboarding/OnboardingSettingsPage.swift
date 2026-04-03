//
//  OnboardingSettingsPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingSettingsPage: View {
    @Bindable private var globalManager = GlobalManager.shared
    #if os(iOS)
    @Bindable private var backgroundTaskHelper = BackgroundTaskHelper.shared
    @Bindable private var activityManager = ActivityManager.shared
    @State private var isBackgroundTaskNotificationDeniedAlertPresented = false
    #endif

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection
                appearanceCard

                #if os(iOS)
                backgroundTaskCard
                activityCard
                #endif
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if os(iOS)
        .alert("通知权限被拒绝", isPresented: $isBackgroundTaskNotificationDeniedAlertPresented) {
            Button("取消", role: .cancel) {
                isBackgroundTaskNotificationDeniedAlertPresented = false
            }
            Button("前往设置") {
                NotificationManager.shared.openAppNotificationSettings()
                isBackgroundTaskNotificationDeniedAlertPresented = false
            }
        } message: {
            Text("需要开启通知权限以启用后台任务，请前往系统设置开启通知权限。")
        }
        #endif
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            Text("偏好设置")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("配置App的外观及相关权限。所有选项均可在应用内设置中重新修改。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private var appearanceCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("外观主题")
                    .font(.headline)

                Picker("外观主题", selection: $globalManager.appearance) {
                    Text("跟随系统").tag("system")
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                }
                .pickerStyle(.segmented)

                Text("您可以按照自己的使用习惯选择显示风格。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }

    #if os(iOS)
    private var backgroundTaskCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("后台任务")
                    .font(.headline)

                Toggle("开启后台任务总开关", isOn: backgroundTaskEnabledBinding)

                Text("包含成绩查询、宿舍电量查询具体后台任务，可以前往“后台任务设置”页面进一步调整。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }

    private var activityCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 14) {
                Text("实时活动/灵动岛")
                    .font(.headline)

                Toggle("开启实时活动/灵动岛", isOn: $activityManager.isEnabled)

                Text("开启后会在上课前、上课中和下课后展示课程状态。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }

    private var backgroundTaskEnabledBinding: Binding<Bool> {
        Binding(
            get: { backgroundTaskHelper.isEnabled },
            set: { newValue in
                Task { @MainActor in
                    let didSucceed = await backgroundTaskHelper.setEnabledByUser(newValue)
                    handleBackgroundTaskToggleResult(isEnabled: newValue, didSucceed: didSucceed)
                }
            }
        )
    }

    @MainActor
    private func handleBackgroundTaskToggleResult(isEnabled: Bool, didSucceed: Bool) {
        guard isEnabled, !didSucceed else { return }
        isBackgroundTaskNotificationDeniedAlertPresented = true
    }
    #endif
}
