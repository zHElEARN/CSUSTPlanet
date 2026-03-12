//
//  ProfileView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import ActivityKit
import Kingfisher
import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) var authManager
    @Environment(GlobalManager.self) var globalManager
    #if os(iOS)
    @Environment(NotificationManager.self) var notificationManager
    #endif

    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        @Bindable var bindableGlobalManager = globalManager

        Form {
            Section(header: Text("账号管理")) {
                if let ssoProfile = authManager.ssoProfile {
                    TrackLink(destination: ProfileDetailView(authManager: authManager)) {
                        HStack {
                            if let avatarUrl = URL(string: ssoProfile.avatar) {
                                let resource = KF.ImageResource(
                                    downloadURL: avatarUrl,
                                    cacheKey: avatarUrl.absoluteString.components(separatedBy: "?").first ?? ssoProfile.avatar
                                )
                                KFImage(source: .network(resource))
                                    .placeholder {
                                        ProgressView()
                                    }
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                VStack(alignment: .leading) {
                                    Text("\(ssoProfile.userName) \(ssoProfile.userAccount)")
                                        .font(.headline)
                                    Text(ssoProfile.deptName)
                                        .font(.caption)
                                }
                            } else {
                                ProgressView()
                            }
                        }
                    }

                    if authManager.isSSOLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录统一身份认证...")
                        }
                    } else {
                        Button(action: authManager.ssoRelogin) {
                            HStack {
                                ColoredLabel(title: "刷新统一身份认证登录", iconName: "person.fill", color: .blue)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isSSOLoggedIn)
                    }

                    if authManager.isEducationLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录教务系统...")
                        }
                    } else {
                        Button(action: authManager.educationLogin) {
                            HStack {
                                ColoredLabel(title: "刷新教务系统登录", iconName: "graduationcap", color: .orange)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isSSOLoggedIn)
                    }

                    if authManager.isMoocLoggingIn {
                        HStack {
                            ProgressView().padding(.horizontal, 6)
                            Text("正在登录网络课程中心...")
                        }
                    } else {
                        Button(action: authManager.moocLogin) {
                            HStack {
                                ColoredLabel(title: "刷新网络课程中心登录", iconName: "book.closed", color: .mint)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!authManager.isSSOLoggedIn)
                    }

                    Button(action: viewModel.showLogoutAlert) {
                        HStack {
                            ColoredLabel(title: "退出登录", iconName: "arrow.right.circle", color: .red, textColor: .red)
                            Spacer()
                            if authManager.isSSOLoggingOut {
                                ProgressView()
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .disabled(authManager.isSSOLoggingOut)
                    .buttonStyle(PlainButtonStyle())
                } else if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView()
                        Text("正在登录统一身份认证...")
                    }
                } else {
                    Button(action: {
                        viewModel.isLoginSheetPresented = true
                    }) {
                        HStack {
                            ColoredLabel(title: "登录统一认证账号", iconName: "person.crop.circle.badge.plus", color: .blue)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Section {
                HStack {
                    ColoredLabel(title: "外观主题")

                    Spacer()

                    Picker("", selection: $bindableGlobalManager.appearance) {
                        Text("浅色").tag("light")
                        Text("深色").tag("dark")
                        Text("系统").tag("system")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 150)
                }

                Toggle(isOn: $viewModel.isWebVPNEnabled) {
                    ColoredLabel(title: "开启WebVPN模式（实验）", description: "通过WebVPN模式访问校园网资源")
                }

                Toggle(isOn: $bindableGlobalManager.isBackgroundTaskEnabled) {
                    ColoredLabel(title: "开启后台任务", description: "开启后应用可以在后台定期刷新课程，并在成绩更新时发送通知（后台任务受系统调度）")
                }

                TrackLink(destination: NotificationSettingsView()) {
                    Label("通知设置", systemImage: "bell.badge")
                }
            } header: {
                Text("设置")
            }

            Section {
                TrackLink(destination: AboutView()) {
                    Text("关于 长理星球")
                }

                TrackLink(destination: FeedbackView()) {
                    Text("意见反馈")
                }

                TrackLink(destination: UserAgreementView()) {
                    Text("长理星球 用户协议")
                }
            } header: {
                Text("帮助与支持")
            }
        }
        .navigationTitle("我的")
        .sheet(isPresented: $viewModel.isLoginSheetPresented) {
            SSOLoginView(isShowingLoginSheet: $viewModel.isLoginSheetPresented)
        }
        .sheet(isPresented: $viewModel.isWebVPNSheetPresented) {
            WebVPNGuideView(isPresented: $viewModel.isWebVPNSheetPresented)
        }
        .alert("关闭 WebVPN 模式", isPresented: $viewModel.isWebVPNDisableAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("关闭并重启", role: .destructive, action: viewModel.dismissWebVPNDisableAlert)
        } message: {
            Text("关闭 WebVPN 模式需要重启应用才能生效。")
        }
        .alert("退出登录", isPresented: $viewModel.isLogoutAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive, action: viewModel.confirmLogout)
        } message: {
            Text("确定要退出登录吗？")
        }
        #if os(iOS)
        .alert("错误", isPresented: Bindable(notificationManager).isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(notificationManager.errorDescription)
        }
        #endif
        .trackView("Profile")
    }
}
