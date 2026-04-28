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
    enum LoginTab {
        case account
        case web
    }

    var selectedTab: LoginTab = .account

    var username: String = KeychainUtil.ssoUsername ?? ""
    var password: String = KeychainUtil.ssoPassword ?? ""
    var captcha: String = ""

    var isNeedCaptcha: Bool = false
    var isPasswordVisible: Bool = false

    var captchaImageData: Data? = nil

    var errorToast: ToastState = .errorTitle

    func login(_ done: () -> Void) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorToast.show(message: "请输入用户名或密码")
            return
        }

        do {
            let loginForm = try await AuthManager.shared.ssoHelper.getLoginForm()
            try await AuthManager.shared.ssoLogin(loginForm: loginForm, username: username, password: password, captcha: captcha)
            done()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func checkNeedCaptcha() {
        Task {
            let isNeedCaptcha = (try? await AuthManager.shared.ssoCheckNeedCaptcha(username: username)) ?? false
            if isNeedCaptcha {
                captchaImageData = try await AuthManager.shared.ssoGetCaptcha()
                withAnimation { self.isNeedCaptcha = true }
            }
        }
    }

    func refreshCaptcha() async {
        do {
            captchaImageData = try await AuthManager.shared.ssoGetCaptcha()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func onBrowserLoginSuccess(_ username: String, _ password: String, _ mode: SSOBrowserView.LoginMode, _ cookies: [HTTPCookie], _ done: @escaping () -> Void) {
        Task {
            do {
                try await AuthManager.shared.ssoBrowserLogin(username: username, password: password, shouldPersistCredentials: mode == .username, cookies: cookies)
                done()
            } catch {
                errorToast.show(message: "通过网页登录失败: \(error.localizedDescription)")
            }
        }
    }
}
