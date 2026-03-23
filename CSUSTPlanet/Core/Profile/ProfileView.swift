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
    @Bindable var authManager = AuthManager.shared
    @Bindable var globalManager = GlobalManager.shared

    #if os(iOS)
    @Environment(NotificationManager.self) var notificationManager
    #endif

    @State var isLoginSheetPresented = false
    @State var isLogoutAlertPresented = false

    var body: some View {
        Form {
            Section {
                if let ssoProfile = authManager.ssoProfile {
                    TrackLink(destination: ProfileDetailView()) {
                        HStack {
                            if let avatarUrl = URL(string: ssoProfile.avatar) {
                                let resource = KF.ImageResource(
                                    downloadURL: avatarUrl,
                                    cacheKey: avatarUrl.absoluteString.components(separatedBy: "?").first ?? ssoProfile.avatar
                                )
                                KFImage(source: .network(resource))
                                    .placeholder {
                                        ProgressView().smallControlSizeOnMac()
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
                                ProgressView().smallControlSizeOnMac()
                            }
                        }
                    }

                    HStack {
                        Button(action: authManager.ssoRelogin) {
                            Label("刷新统一身份认证登录", systemImage: "person.fill")
                        }
                        .disabled(!authManager.isSSOLoggedIn)
                        if authManager.isSSOLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    HStack {
                        Button(action: authManager.educationLogin) {
                            Label("刷新教务系统登录", systemImage: "graduationcap")
                        }
                        .disabled(!authManager.isSSOLoggedIn || authManager.isEducationLoggingIn)
                        if authManager.isEducationLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    HStack {
                        Button(action: authManager.moocLogin) {
                            Label("刷新网络课程中心登录", systemImage: "book.closed")
                        }
                        .disabled(!authManager.isSSOLoggedIn || authManager.isMoocLoggingIn)
                        if authManager.isMoocLoggingIn {
                            Spacer()
                            ProgressView().smallControlSizeOnMac()
                        }
                    }

                    Button(action: { isLogoutAlertPresented = true }) {
                        Label("退出登录", systemImage: "arrow.right.circle").foregroundColor(.red)
                    }
                    .disabled(authManager.isSSOLoggingOut)
                } else if authManager.isSSOLoggingIn {
                    HStack {
                        ProgressView().smallControlSizeOnMac()
                        Text("正在登录统一身份认证...")
                    }
                } else {
                    Button(action: { isLoginSheetPresented = true }) {
                        Label("登录统一认证账号", systemImage: "person.crop.circle.badge.plus")
                    }
                }
            } header: {
                Text("账号管理")
            }

            Section {
                Picker("外观主题", selection: $globalManager.appearance) {
                    Text("浅色模式").tag("light")
                    Text("深色模式").tag("dark")
                    Text("跟随系统").tag("system")
                }

                TrackLink(destination: NetworkSettingsView()) {
                    Label("网络设置", systemImage: "network")
                }

                #if os(iOS)
                TrackLink(destination: BackgroundTaskSettingsView()) {
                    Label("后台任务设置", systemImage: "gearshape.2")
                }
                #endif

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
        .formStyle(.grouped)
        .navigationTitle("我的")
        .sheet(isPresented: $isLoginSheetPresented) {
            SSOLoginView(isPresented: $isLoginSheetPresented)
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
