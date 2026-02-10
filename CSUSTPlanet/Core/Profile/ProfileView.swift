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
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var globalManager: GlobalManager
    @EnvironmentObject var notificationManager: NotificationManager

    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {

        NavigationStack {
            Form {
                Section(header: Text("账号管理")) {
                    if let ssoProfile = authManager.ssoProfile {
                        TrackLink(destination: ProfileDetailView(authManager: authManager)) {
                            HStack {
                                let avatarUrl = URL(string: ssoProfile.avatar)
                                let resource = avatarUrl.map { url in
                                    KF.ImageResource(
                                        downloadURL: url,
                                        cacheKey: url.absoluteString.components(separatedBy: "?").first ?? ssoProfile.avatar
                                    )
                                }
                                KFImage(source: resource != nil ? .network(resource!) : nil)
                                    .placeholder {
                                        ProgressView()
                                            .frame(width: 40, height: 40)
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

                Section(header: Text("设置")) {
                    HStack {
                        ColoredLabel(title: "外观主题")

                        Spacer()

                        Picker("", selection: $globalManager.appearance) {
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

                    Toggle(isOn: $viewModel.isNotificationEnabled) {
                        ColoredLabel(title: "开启通知", description: "用于宿舍电量定时查询提醒通知")
                    }

                    Toggle(isOn: $globalManager.isBackgroundTaskEnabled) {
                        ColoredLabel(title: "开启后台任务", description: "开启后应用可以在后台定期刷新课程，并在成绩更新时发送通知（后台任务受系统调度）")
                    }

                    Toggle(isOn: $viewModel.isLiveActivityEnabled) {
                        ColoredLabel(title: "启用实时活动/灵动岛", description: "实时活动/灵动岛将会显示：上课前20分钟、上课中和下课后5分钟的课程状态")
                    }
                }

                Section(header: Text("帮助与支持")) {
                    TrackLink(destination: AboutView()) {
                        ColoredLabel(title: "关于 长理星球")
                    }

                    TrackLink(destination: FeedbackView()) {
                        ColoredLabel(title: "意见反馈")
                    }

                    TrackLink(destination: UserAgreementView()) {
                        ColoredLabel(title: "长理星球 用户协议")
                    }
                }
            }
            .navigationTitle("我的")
            .toolbarTitleDisplayMode(.inline)
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
            .alert("错误", isPresented: $notificationManager.isShowingError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(notificationManager.errorDescription)
            }
            .trackView("Profile")
        }
        .tabItem {
            Image(uiImage: UIImage(systemName: "person")!)
            Text("我的")
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(GlobalManager.shared)
    .environmentObject(NotificationManager.shared)
}
