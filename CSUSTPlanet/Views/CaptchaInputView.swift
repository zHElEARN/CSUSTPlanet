//
//  CaptchaInputView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/28.
//

import SwiftUI

struct CaptchaInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var authManager = AuthManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("验证码", text: $authManager.captcha)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                            #if os(iOS)
                        .textInputAutocapitalization(.never)
                            #endif

                        if let data = authManager.captchaImageData {
                            #if os(macOS)
                            if let nsImage = NSImage(data: data) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 28)
                                    .contentShape(.rect)
                                    .onTapGesture { Task { try? await authManager.ssoRefreshCaptcha() } }
                            }
                            #else
                            if let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 28)
                                    .contentShape(.rect)
                                    .onTapGesture { Task { try? await authManager.ssoRefreshCaptcha() } }
                            }
                            #endif
                        } else {
                            ProgressView()
                                .smallControlSizeOnMac()
                                .frame(width: 100)
                        }
                    }
                } footer: {
                    Text("统一身份认证登录状态失效，重新登录需要输入验证码。")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("需要验证码")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("确定") {
                        dismiss()
                    }
                    .disabled(authManager.captcha.isEmpty)
                }
            }
        }
    }
}
