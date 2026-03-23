//
//  SSOLoginViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import Alamofire
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

    var isGetDynamicCodeDisabled: Bool {
        return captcha.isEmpty || username.isEmpty || countdown > 0 || AuthManager.shared.isSSOLoggingIn
    }

    var isDynamicLoginDisabled: Bool {
        return username.isEmpty || captcha.isEmpty || smsCode.isEmpty || AuthManager.shared.isSSOLoggingIn
    }

    var isToolbarLoginDisabled: Bool {
        switch selectedTab {
        case 0:
            isAccountLoginDisabled
        case 1:
            isDynamicLoginDisabled
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
        case 1:
            await handleDynamicLogin(isLoginSheetPresented: isLoginSheetPresented)
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
            try await AuthManager.shared.ssoLogin(username: username, password: password)
            isLoginSheetPresented.wrappedValue = false
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func handleGetDynamicCode() async {
        guard !username.isEmpty, !captcha.isEmpty else {
            errorToast.show(message: "请输入用户名和验证码")
            return
        }

        do {
            try await AuthManager.shared.ssoGetDynamicCode(username: username, captcha: captcha)

            countdown = 120
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                Task { @MainActor in
                    guard let self = self else {
                        timer.invalidate()
                        return
                    }
                    if self.countdown > 1 {
                        self.countdown -= 1
                    } else {
                        timer.invalidate()
                        self.countdown = 0
                    }
                }
            }
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

    func handleDynamicLogin(isLoginSheetPresented: Binding<Bool>) async {
        do {
            try await AuthManager.shared.ssoDynamicLogin(username: username, captcha: captcha, dynamicCode: smsCode)
            isLoginSheetPresented.wrappedValue = false
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func onBrowserLoginSuccess(_ username: String, _ password: String, _ mode: SSOBrowserView.LoginMode, _ cookies: [HTTPCookie], _ isLoginSheetPresented: Binding<Bool>) {
        CookieHelper.shared.updateCookies(cookies)
        Task {
            do {
                let ssoProfile = try await AuthManager.shared.ssoHelper.getLoginUser()
                isLoginSheetPresented.wrappedValue = false
                AuthManager.shared.ssoProfile = ssoProfile
                MMKVHelper.shared.userId = ssoProfile.userAccount
                TrackHelper.shared.updateUserID(ssoProfile.userAccount)
                CookieHelper.shared.save()
                AuthManager.shared.ssoInfo = "统一身份认证登录成功"
                AuthManager.shared.isShowingSSOInfo = true
                AuthManager.shared.allLogin()
                TrackHelper.shared.event(category: "Auth", action: "Login", name: "Browser", value: 1)
                if mode == .username {
                    KeychainUtil.ssoUsername = username
                    KeychainUtil.ssoPassword = password
                }
            } catch {
                errorToast.show(message: "通过网页登录失败: \(error.localizedDescription)")
                TrackHelper.shared.event(category: "Auth", action: "Login", name: "Browser", value: 0)
            }
        }
    }
}
