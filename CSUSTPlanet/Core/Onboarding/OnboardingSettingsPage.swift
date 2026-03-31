//
//  OnboardingSettingsPage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingSettingsPage: View {
    @Bindable private var globalManager = GlobalManager.shared
    #if os(iOS)
    @Bindable private var backgroundTaskHelper = BackgroundTaskHelper.shared
    @Bindable private var activityManager = ActivityManager.shared
    #endif

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(.accent)
                        .padding(.top, 24)

                    Text("完成基础设置")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("先把常用偏好配置好，进入 App 后也可以随时前往“我的”页面继续调整。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                }

                VStack(spacing: 16) {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("外观主题", systemImage: "circle.lefthalf.filled")
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
                    }
                    .padding(.horizontal, 8)

                    #if os(iOS)
                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("后台任务", systemImage: "gearshape.2")
                                .font(.headline)

                            Toggle("开启后台任务总开关", isOn: backgroundTaskEnabledBinding)

                            Text("这里只提供总开关。成绩更新、宿舍电量等具体后台任务，后续可以前往“我的”页面进一步调整。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 8)

                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("实时活动与灵动岛", systemImage: "dot.radiowaves.left.and.right")
                                .font(.headline)

                            Toggle("开启实时活动", isOn: $activityManager.isEnabled)

                            Text("开启后会在上课前、上课中和下课后展示课程状态，支持实时活动与灵动岛显示。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.horizontal, 8)
                    #endif
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    #if os(iOS)
    private var backgroundTaskEnabledBinding: Binding<Bool> {
        Binding(
            get: { backgroundTaskHelper.isEnabled },
            set: { newValue in
                withAnimation {
                    backgroundTaskHelper.isEnabled = newValue
                }
            }
        )
    }
    #endif
}

#Preview {
    OnboardingSettingsPage()
        .padding()
}
