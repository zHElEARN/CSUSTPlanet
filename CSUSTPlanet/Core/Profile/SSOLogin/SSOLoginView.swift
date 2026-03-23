//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct SSOLoginView: View {
    @Binding var isPresented: Bool

    @State var viewModel = SSOLoginViewModel()
    @Bindable var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("登录方式", selection: $viewModel.selectedTab.withAnimation(.snappy)) {
                        Text("账号登录").tag(0)
                        Text("验证码登录").tag(1)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Label {
                        Text("推荐使用账号密码登录方式，当登录状态丢失后，应用会自动尝试重新使用账号密码来登录。验证码登录方式在登录状态丢失后需要重新登录。")
                    } icon: {
                        Image(systemName: "info.circle.fill")
                    }
                }

                if viewModel.selectedTab == 0 {
                    accountLoginSection
                } else {
                    verificationCodeLoginSection
                }
            }
            .formStyle(.grouped)
            .navigationTitle("统一认证登录")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("网页登录") {
                        if GlobalManager.shared.isWebVPNModeEnabled {
                            viewModel.isShowingWebVPNAlert = true
                        } else {
                            viewModel.isShowingBrowser = true
                        }
                    }
                }
            }
            .errorToast($viewModel.errorToast)
            .task { await viewModel.handleRefreshCaptcha() }
            .alert("警告", isPresented: $viewModel.isShowingWebVPNAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("WebVPN模式下无法使用网页登录，请关闭WebVPN模式后重试。")
            }
            .sheet(isPresented: $viewModel.isShowingBrowser) {
                SSOBrowserView(isPresented: $viewModel.isShowingBrowser) { username, password, loginMode, cookies in
                    viewModel.onBrowserLoginSuccess(username, password, loginMode, cookies, $isPresented)
                }
                .trackView("SSOBrowser")
            }
        }
        .trackView("SSOLogin")
    }

    // MARK: - Account Login View

    private var accountLoginSection: some View {
        Group {
            Section("账号信息") {
                TextField("请输入账号", text: $viewModel.username)
                    .textContentType(.username)
                    #if os(iOS)
                .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)

                HStack {
                    Group {
                        if viewModel.isPasswordVisible {
                            TextField("请输入密码", text: $viewModel.password)
                        } else {
                            SecureField("请输入密码", text: $viewModel.password)
                                .autocorrectionDisabled(true)
                        }
                    }
                    .textContentType(.password)

                    Button(action: { viewModel.isPasswordVisible.toggle() }) {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button(asyncAction: { await viewModel.handleAccountLogin(isLoginSheetPresented: $isPresented) }) {
                    HStack {
                        Text("登录")
                            .frame(maxWidth: .infinity)
                        if authManager.isSSOLoggingIn {
                            ProgressView()
                                .smallControlSizeOnMac()
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isAccountLoginDisabled)
            }
        }
    }

    // MARK: - Verification Code Login View

    private var verificationCodeLoginSection: some View {
        Group {
            Section {
                TextField("请输入账号", text: $viewModel.username)
                    .textContentType(.username)
                    #if os(iOS)
                .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled(true)

                HStack {
                    TextField("请输入图片验证码", text: $viewModel.captcha)
                        #if os(iOS)
                    .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled(true)

                    if let data = viewModel.captchaImageData {
                        #if os(macOS)
                        if let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 28)
                                .contentShape(.rect)
                                .onTapGesture { Task { await viewModel.handleRefreshCaptcha() } }
                        }
                        #else
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 28)
                                .contentShape(.rect)
                                .onTapGesture { Task { await viewModel.handleRefreshCaptcha() } }
                        }
                        #endif
                    } else {
                        ProgressView()
                            .smallControlSizeOnMac()
                            .frame(width: 100)
                    }
                }

                HStack {
                    TextField("请输入短信验证码", text: $viewModel.smsCode)
                        .textContentType(.oneTimeCode)
                        #if os(iOS)
                    .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled(true)

                    Button(asyncAction: viewModel.handleGetDynamicCode) {
                        Text(viewModel.countdown > 0 ? "\(viewModel.countdown)秒后重新获取" : "获取验证码")
                    }
                    .disabled(viewModel.isGetDynamicCodeDisabled)
                }
            } header: {
                Text("验证码登录")
            } footer: {
                Text("点击图片验证码可刷新。")
            }

            Section {
                Button(asyncAction: { await viewModel.handleDynamicLogin(isLoginSheetPresented: $isPresented) }) {
                    HStack {
                        Text("登录")
                            .frame(maxWidth: .infinity)
                        if authManager.isSSOLoggingIn {
                            ProgressView()
                                .smallControlSizeOnMac()
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isDynamicLoginDisabled)
            }
        }
    }
}
