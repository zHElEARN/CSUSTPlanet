//
//  SSOLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct SSOLoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewModel = SSOLoginViewModel()
    @Bindable var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            Group {
                #if os(iOS)
                TabView(selection: $viewModel.selectedTab) {
                    Form {
                        accountLoginSection
                    }
                    .tag(SSOLoginViewModel.LoginTab.account)

                    webLoginSection.tag(SSOLoginViewModel.LoginTab.web)
                }
                .tabViewStyle(.page)
                #elseif os(macOS)
                NavigationSplitView {
                    List(selection: $viewModel.selectedTab) {
                        Label("账号登录", systemImage: "person").tag(SSOLoginViewModel.LoginTab.account)
                        Label("网页登录", systemImage: "globe").tag(SSOLoginViewModel.LoginTab.web)
                    }
                } detail: {
                    switch viewModel.selectedTab {
                    case .account:
                        Form { accountLoginSection }
                    case .web:
                        webLoginSection
                    }
                }
                #endif
            }
            .formStyle(.grouped)
            #if os(iOS)
            .navigationTitle("统一身份认证登录")
            .inlineToolbarTitle()
            .background(Color(PlatformColor.systemGroupedBackground))
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    Picker("登录方式", selection: $viewModel.selectedTab) {
                        Text("账号登录").tag(SSOLoginViewModel.LoginTab.account)
                        Text("网页登录").tag(SSOLoginViewModel.LoginTab.web)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }
                #endif

                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(asyncAction: { await viewModel.handleAccountLogin { dismiss() } }) {
                        HStack {
                            Text("登录")
                            if authManager.isSSOLoggingIn {
                                ProgressView().smallControlSizeOnMac()
                            }
                        }
                    }
                    .disabled(viewModel.selectedTab == .account ? (viewModel.username.isEmpty || viewModel.password.isEmpty || AuthManager.shared.isSSOLoggingIn) : true)
                }
            }
            .errorToast($viewModel.errorToast)
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 540)
        #endif
    }

    // MARK: - Account Login Section

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
            Text("如果您不记得账号或密码，可以切换到 **“网页登录”** 尝试找回。\n\n账号密码将安全地保存在您的设备本地。当登录状态失效时，程序会自动帮您重新登录，无需反复手动输入。")
        }
    }

    // MARK: - Web Login Section

    @ViewBuilder
    private var webLoginSection: some View {
        SSOBrowserView { username, password, loginMode, cookies in
            viewModel.onBrowserLoginSuccess(username, password, loginMode, cookies) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
