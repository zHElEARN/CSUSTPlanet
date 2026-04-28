//
//  SSOLoginViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
class SSOLoginViewModel {
    var isBrowserPresented: Bool = false
    var isWebVPNAlertPresented: Bool = false
    var selectedTab: Int = 0

    var username: String = KeychainUtil.ssoUsername ?? ""
    var password: String = KeychainUtil.ssoPassword ?? ""
    var isPasswordVisible: Bool = false

    var captchaImageData: Data? = nil
    var captcha: String = ""
    var smsCode: String = ""

    var errorToast: ToastState = .errorTitle

    var countdown = 0

    var isAccountLoginDisabled: Bool {
        return username.isEmpty || password.isEmpty || AuthManager.shared.isSSOLoggingIn
    }

    var isToolbarLoginDisabled: Bool {
        switch selectedTab {
        case 0:
            isAccountLoginDisabled
        case 2:
            true
        default:
            true
        }
    }

    func handleToolbarLogin(isLoginSheetPresented: Binding<Bool>) async {
        switch selectedTab {
        case 0:
            await handleAccountLogin(isLoginSheetPresented: isLoginSheetPresented)
        case 2:
            break
        default:
            break
        }
    }

    func handleAccountLogin(isLoginSheetPresented: Binding<Bool>) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorToast.show(message: "请输入用户名或密码")
            return
        }

        do {
            let loginForm = try await AuthManager.shared.ssoGetLoginForm()
            try await AuthManager.shared.ssoLogin(loginForm: loginForm, username: username, password: password)
            isLoginSheetPresented.wrappedValue = false
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func handleRefreshCaptcha() async {
        do {
            captchaImageData = try await AuthManager.shared.ssoGetCaptcha()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func onBrowserLoginSuccess(_ username: String, _ password: String, _ mode: SSOBrowserView.LoginMode, _ cookies: [HTTPCookie], _ isLoginSheetPresented: Binding<Bool>) {
        Task {
            do {
                try await AuthManager.shared.ssoBrowserLogin(username: username, password: password, shouldPersistCredentials: mode == .username, cookies: cookies)
                isLoginSheetPresented.wrappedValue = false
            } catch {
                errorToast.show(message: "通过网页登录失败: \(error.localizedDescription)")
            }
        }
    }
}
