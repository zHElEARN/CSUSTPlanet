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

    @State var isLoginSheetPresented = false
    @State var isLogoutAlertPresented = false

    var body: some View {
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

                    Button(action: { isLogoutAlertPresented = true }) {
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
                    Button(action: { isLoginSheetPresented = true }) {
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
                Picker("外观主题", selection: Bindable(globalManager).appearance) {
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                    Text("跟随系统").tag("system")
                }

                TrackLink(destination: NetworkSettingsView()) {
                    Label("网络设置", systemImage: "network")
                }

                TrackLink(destination: BackgroundTaskSettingsView()) {
                    Label("后台任务设置", systemImage: "gearshape.2")
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
        .sheet(isPresented: $isLoginSheetPresented) {
            SSOLoginView(isShowingLoginSheet: $isLoginSheetPresented)
        }
        .alert("退出登录", isPresented: $isLogoutAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive, action: { AuthManager.shared.ssoLogout() })
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
