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
            TabView(selection: $viewModel.selectedTab) {
                Form {
                    accountLoginSection
                }
                .formStyle(.grouped)
                .tabItem {
                    Label("账号登录", systemImage: "person.text.rectangle")
                }
                .tag(0)

                Form {
                    verificationCodeLoginSection
                }
                .formStyle(.grouped)
                .tabItem {
                    Label("验证码登录", systemImage: "message.badge")
                }
                .tag(1)

                Form {
                    webLoginSection
                }
                .formStyle(.grouped)
                .tabItem {
                    Label("网页登录", systemImage: "safari")
                }
                .tag(2)
            }
            #if os(macOS)
            .frame(minWidth: 350, minHeight: 400)
            #endif
            #if os(iOS)
            .navigationTitle("统一身份认证登录")
            .inlineToolbarTitle()
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(asyncAction: { await viewModel.handleToolbarLogin(isLoginSheetPresented: $isPresented) }) {
                        HStack {
                            Text("登录")
                            if authManager.isSSOLoggingIn {
                                ProgressView()
                                    .smallControlSizeOnMac()
                            }
                        }
                    }
                    .disabled(viewModel.isToolbarLoginDisabled)
                }
            }
            .errorToast($viewModel.errorToast)
            .alert("警告", isPresented: $viewModel.isWebVPNAlertPresented) {
                Button("确定", role: .cancel) {}
            } message: {
                Text("WebVPN模式下无法使用网页登录，请关闭WebVPN模式后重试。")
            }
            .sheet(isPresented: $viewModel.isBrowserPresented) {
                SSOBrowserView(isPresented: $viewModel.isBrowserPresented) { username, password, loginMode, cookies in
                    viewModel.onBrowserLoginSuccess(username, password, loginMode, cookies, $isPresented)
                }
            }
        }
        .trackView("SSOLogin")
    }

    // MARK: - Account Login View

    @ViewBuilder
    private var accountLoginSection: some View {
        Section {
            TextField("账号", text: $viewModel.username)
                .textContentType(.username)
                #if os(iOS)
            .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled(true)

            HStack {
                Group {
                    if viewModel.isPasswordVisible {
                        TextField("密码", text: $viewModel.password)
                    } else {
                        SecureField("密码", text: $viewModel.password)
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
        } header: {
            Text("账号信息")
        } footer: {
            Text("如果您不记得账号或密码，可以切换到“网页登录”尝试找回。\n\n账号密码将安全地保存在您的设备本地。当登录状态失效时，程序会自动帮您重新登录，无需反复手动输入。")
        }
    }

    // MARK: - Verification Code Login View

    @ViewBuilder
    private var verificationCodeLoginSection: some View {
        Section {
            TextField("账号", text: $viewModel.username)
                .textContentType(.username)
                #if os(iOS)
            .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled(true)

            HStack {
                TextField("图片验证码", text: $viewModel.captcha)
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
                TextField("短信验证码", text: $viewModel.smsCode)
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
            Text("点击图片验证码可刷新。\n\n注意：使用验证码登录时，系统无法保存您的密码凭证。一旦一段时间后登录状态失效，您将需要再次手动获取验证码登录。\n\n推荐：为了更省心的体验，建议优先使用“账号登录”或“网页登录”中的密码方式，它们支持在失效后为您自动重新登录。")
        }
        .task { await viewModel.handleRefreshCaptcha() }
    }

    // MARK: - Web Login View

    @ViewBuilder
    private var webLoginSection: some View {
        Section {
            Button("打开网页登录") {
                if GlobalManager.shared.isWebVPNModeEnabled {
                    viewModel.isWebVPNAlertPresented = true
                } else {
                    viewModel.isBrowserPresented = true
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        } footer: {
            Text("将打开学校官网进行登录，您也可以在官网页面中找回忘记的密码。\n\n建议您在网页中选择“账号密码登录”方式。这样系统可以在本地安全地保存您的账号密码，未来登录状态丢失时可为您自动恢复，免去频繁手动登录的烦恼。")
        }
    }
}
