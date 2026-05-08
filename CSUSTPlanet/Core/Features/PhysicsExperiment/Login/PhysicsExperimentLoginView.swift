//
//  PhysicsExperimentLoginView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import SwiftUI

struct PhysicsExperimentLoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = PhysicsExperimentLoginViewModel()
    @Bindable var physicsExperimentManager = PhysicsExperimentManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("用户名", text: $viewModel.username)
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
                    Text("登录信息")
                } footer: {
                    Text("需要在校园网内或者启用WebVPN模式才能登录物理实验教学管理平台，请确保您已连接到校园网。否则无法登录。")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("登录大物实验")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("关闭")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(asyncAction: {
                        await viewModel.login {
                            dismiss()
                        }
                    }) {
                        if physicsExperimentManager.isLoggingIn {
                            ProgressView()
                                .smallControlSizeOnMac()
                        } else {
                            Text("登录")
                        }
                    }
                    .disabled(viewModel.isLoginDisabled)
                }
            }
            .errorToast($viewModel.errorToast)
        }
    }
}

#Preview {
    PhysicsExperimentLoginView()
}
