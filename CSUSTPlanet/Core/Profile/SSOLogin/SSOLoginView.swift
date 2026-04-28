//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct SSOLoginView: View {
    private struct LoginTabItem: Identifiable {
        let id: Int
        let title: String
        let systemImage: String
    }

    private static let loginTabItems: [LoginTabItem] = [
        LoginTabItem(id: 0, title: "账号登录", systemImage: "person.text.rectangle"),
        LoginTabItem(id: 2, title: "网页登录", systemImage: "safari"),
    ]

    @Binding var isPresented: Bool

    @State var viewModel = SSOLoginViewModel()
    @Bindable var authManager = AuthManager.shared

    #if os(macOS)
    private let isCompactEnv = false
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompactEnv: Bool { horizontalSizeClass == .compact }
    #endif

    var body: some View {
        NavigationStack {
            Group {
                #if os(macOS)
                legacyLayout
                #else
                if #available(iOS 18.0, *) {
                    modernLayout
                } else {
                    legacyLayout
                }
                #endif
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
    }

    // MARK: - Modern Layout

    @available(iOS 18.0, macOS 15.0, *)
    @ViewBuilder
    private var modernLayout: some View {
        if isCompactEnv {
            TabView(selection: $viewModel.selectedTab) {
                Tab("账号登录", systemImage: "person.text.rectangle", value: 0) {
                    loginForm(for: 0)
                }

                Tab("验证码登录", systemImage: "message.badge", value: 1) {
                    loginForm(for: 1)
                }

                Tab("网页登录", systemImage: "safari", value: 2) {
                    loginForm(for: 2)
                }
            }
        } else {
            splitLayout
        }
    }

    // MARK: - Legacy Layout

    @ViewBuilder
    private var legacyLayout: some View {
        if isCompactEnv {
            TabView(selection: $viewModel.selectedTab) {
                loginForm(for: 0)
                    .tabItem {
                        Label("账号登录", systemImage: "person.text.rectangle")
                    }
                    .tag(0)

                loginForm(for: 1)
                    .tabItem {
                        Label("验证码登录", systemImage: "message.badge")
                    }
                    .tag(1)

                loginForm(for: 2)
                    .tabItem {
                        Label("网页登录", systemImage: "safari")
                    }
                    .tag(2)
            }
        } else {
            splitLayout
        }
    }

    @ViewBuilder
    private var splitLayout: some View {
        NavigationSplitView {
            List(
                selection: Binding<Int?>(
                    get: { viewModel.selectedTab },
                    set: { newValue in
                        if let newValue {
                            viewModel.selectedTab = newValue
                        }
                    }
                )
            ) {
                ForEach(Self.loginTabItems) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item.id)
                }
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 240)
            #endif
        } detail: {
            loginForm(for: viewModel.selectedTab)
        }
    }

    @ViewBuilder
    private func loginForm(for tab: Int) -> some View {
        Form {
            switch tab {
            case 0:
                accountLoginSection
            case 2:
                webLoginSection
            default:
                accountLoginSection
            }
        }
        .formStyle(.grouped)
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
