//
//  AuthManager.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import Alamofire
import CSUSTKit
import Foundation
import OSLog

@MainActor
@Observable
class AuthManager {
    static let shared = AuthManager()

    // MARK: - SSO Properties

    var ssoProfile: SSOHelper.Profile?
    var isSSOLoggingIn: Bool = false
    var isSSOLoggingOut: Bool = false
    var isShowingSSOError: Bool = false
    var isShowingSSOInfo: Bool = false
    var ssoInfo: String = ""
    var isSSOLoggedIn: Bool { return ssoProfile != nil }

    // MARK: - Education Properties

    var isEducationLoggingIn: Bool = false
    var isShowingEducationError: Bool = false
    var isShowingEducationInfo: Bool = false
    var educationInfo: String = ""

    // MARK: - MOOC Properties

    var isMoocLoggingIn: Bool = false
    var isShowingMoocError: Bool = false
    var isShowingMoocInfo: Bool = false
    var moocInfo: String = ""

    // MARK: - Helpers

    var ssoHelper: SSOHelper
    var eduHelper: EduHelper
    var moocHelper: MoocHelper

    private let mode: ConnectionMode = GlobalManager.shared.isWebVPNModeEnabled ? .webVpn : .direct
    private let session: Session = CookieHelper.shared.session

    private var ssoLoginTask: Task<Void, Error>?
    private var eduLoginTask: Task<Void, Error>?
    private var moocLoginTask: Task<Void, Error>?

    // MARK: - Initializer

    private init() {
        ssoHelper = SSOHelper(mode: mode, session: session)
        eduHelper = EduHelper(mode: mode, session: session)
        moocHelper = MoocHelper(mode: mode, session: session)
        ssoRelogin()
    }

    // MARK: - SSO Login

    // 用于登录界面的ViewModel调用
    func ssoLogin(username: String, password: String) async throws {
        guard !isSSOLoggedIn else { return }
        isSSOLoggingIn = true
        defer { isSSOLoggingIn = false }

        CookieHelper.shared.clearCookies()
        try await ssoHelper.login(username: username, password: password)
        TrackHelper.shared.event(category: "Auth", action: "Login", name: "Account", value: 1)
        KeychainUtil.ssoUsername = username
        KeychainUtil.ssoPassword = password

        let profile = try await ssoHelper.getLoginUser()
        ssoProfile = profile
        MMKVHelper.shared.userId = profile.userAccount
        TrackHelper.shared.updateUserID(profile.userAccount)
        CookieHelper.shared.save()
        await PlanetService.auth.syncTokenAfterManualLogin(ssoUserName: profile.userName, session: session)

        ssoInfo = "统一身份认证登录成功"
        isShowingSSOInfo = true

        allLogin()
    }

    func ssoLogout() {
        guard isSSOLoggedIn else { return }
        Task {
            isSSOLoggingOut = true
            TrackHelper.shared.event(category: "Auth", action: "Logout")
            defer { isSSOLoggingOut = false }
            try? await eduHelper.authService.logout()
            try? await moocHelper.logout()
            try? await ssoHelper.logout()
            CookieHelper.shared.save()
            KeychainUtil.ssoUsername = nil
            KeychainUtil.ssoPassword = nil
            MMKVHelper.shared.userId = nil
            PlanetService.auth.clearToken()
            TrackHelper.shared.updateUserID(nil)
            ssoProfile = nil
        }
    }

    func ssoGetCaptcha() async throws -> Data {
        return try await ssoHelper.getCaptcha()
    }

    func ssoGetDynamicCode(username: String, captcha: String) async throws {
        try await ssoHelper.getDynamicCode(mobile: username, captcha: captcha)
    }

    func ssoDynamicLogin(username: String, captcha: String, dynamicCode: String) async throws {
        guard !isSSOLoggedIn else { return }
        isSSOLoggingIn = true
        defer { isSSOLoggingIn = false }

        try await ssoHelper.dynamicLogin(username: username, dynamicCode: dynamicCode, captcha: captcha)
        TrackHelper.shared.event(category: "Auth", action: "Login", name: "Dynamic", value: 1)

        let profile = try await ssoHelper.getLoginUser()
        ssoProfile = profile
        MMKVHelper.shared.userId = profile.userAccount
        TrackHelper.shared.updateUserID(profile.userAccount)
        CookieHelper.shared.save()
        await PlanetService.auth.syncTokenAfterManualLogin(ssoUserName: profile.userName, session: session)

        ssoInfo = "统一身份认证登录成功"
        isShowingSSOInfo = true

        allLogin()
    }

    // MARK: - SSO Relogin Async

    func ssoReloginAsync() async throws {
        if let task = ssoLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isSSOLoggingIn = true
            defer { isSSOLoggingIn = false }

            if let ssoProfile = try? await ssoHelper.getLoginUser() {
                Logger.authManager.debug("ssoRelogin: 统一身份认证已登录，无需再登录")
                self.ssoProfile = ssoProfile
                MMKVHelper.shared.userId = ssoProfile.userAccount
                TrackHelper.shared.updateUserID(ssoProfile.userAccount)
                await PlanetService.auth.syncTokenAfterAutoLoginIfNeeded(ssoUserName: ssoProfile.userName, session: session)

                ssoInfo = "统一身份认证已登录"
                isShowingSSOInfo = true
                return
            }

            guard let username = KeychainUtil.ssoUsername, let password = KeychainUtil.ssoPassword else {
                Logger.authManager.debug("ssoRelogin: 统一身份认证未登录，密码未保存")
                throw SSOHelper.SSOHelperError.notLoggedIn
            }

            do {
                try await ssoHelper.login(username: username, password: password)
            } catch {
                Logger.authManager.error("ssoRelogin: 统一身份认证登录失败, \(error)")
                TrackHelper.shared.event(category: "Auth", action: "Relogin", value: 0)

                isShowingSSOError = true
                throw error
            }

            if let ssoProfile = try? await ssoHelper.getLoginUser() {
                Logger.authManager.debug("ssoRelogin: 验证统一身份认证登录成功")
                TrackHelper.shared.event(category: "Auth", action: "Relogin", value: 1)
                self.ssoProfile = ssoProfile
                MMKVHelper.shared.userId = ssoProfile.userAccount
                TrackHelper.shared.updateUserID(ssoProfile.userAccount)
                CookieHelper.shared.save()
                await PlanetService.auth.syncTokenAfterAutoLoginIfNeeded(ssoUserName: ssoProfile.userName, session: session)

                ssoInfo = "统一身份认证登录成功"
                isShowingSSOInfo = true
            } else {
                Logger.authManager.debug("ssoRelogin: 验证统一身份认证登录失败")

                isShowingSSOError = true
                throw SSOHelper.SSOHelperError.notLoggedIn
            }
        }

        ssoLoginTask = task
        defer { ssoLoginTask = nil }
        try await task.value
    }

    // MARK: - Education Login Async

    func educationLoginAsync() async throws {
        if let task = eduLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isEducationLoggingIn = true
            defer { isEducationLoggingIn = false }

            let tempEduHelper = EduHelper(mode: mode, session: session)
            if await tempEduHelper.isLoggedIn() {
                Logger.authManager.debug("educationLogin: 教务系统已登录")
                self.eduHelper = tempEduHelper

                educationInfo = "教务系统已登录"
                isShowingEducationInfo = true
                return
            }

            do {
                _ = try await ssoHelper.loginToEducation()
            } catch {
                Logger.authManager.error("educationLogin: 教务登录请求失败, \(error)")
                TrackHelper.shared.event(category: "Auth", action: "Sublogin", name: "Education", value: 0)

                isShowingEducationError = true
                throw error
            }

            if await tempEduHelper.isLoggedIn() {
                Logger.authManager.debug("educationLogin: 验证教务登录成功")
                TrackHelper.shared.event(category: "Auth", action: "Sublogin", name: "Education", value: 1)
                self.eduHelper = tempEduHelper
                CookieHelper.shared.save()

                educationInfo = "教务系统登录成功"
                isShowingEducationInfo = true
            } else {
                Logger.authManager.debug("educationLogin: 验证教务登录失败")

                isShowingEducationError = true
                throw EduHelper.EduHelperError.notLoggedIn
            }
        }

        eduLoginTask = task
        defer { eduLoginTask = nil }
        try await task.value
    }

    // MARK: - Mooc Login Async

    func moocLoginAsync() async throws {
        if let task = moocLoginTask {
            return try await task.value
        }

        let task = Task { @MainActor in
            isMoocLoggingIn = true
            defer { isMoocLoggingIn = false }

            let tempMoocHelper = MoocHelper(mode: mode, session: session)
            if await tempMoocHelper.isLoggedIn() {
                Logger.authManager.debug("moocLogin: 网络课程平台已登录")
                self.moocHelper = tempMoocHelper

                moocInfo = "网络课程平台已登录"
                isShowingMoocInfo = true
                return
            }

            do {
                _ = try await ssoHelper.loginToMooc()
            } catch {
                Logger.authManager.error("moocLogin: 网络课程平台登录请求失败, \(error)")
                TrackHelper.shared.event(category: "Auth", action: "Sublogin", name: "Mooc", value: 0)

                isShowingMoocError = true
                throw error
            }

            if await tempMoocHelper.isLoggedIn() {
                Logger.authManager.debug("moocLogin: 验证网络课程平台登录成功")
                TrackHelper.shared.event(category: "Auth", action: "Sublogin", name: "Mooc", value: 1)
                self.moocHelper = tempMoocHelper
                CookieHelper.shared.save()

                moocInfo = "网络课程平台登录成功"
                isShowingMoocInfo = true
            } else {
                Logger.authManager.debug("moocLogin: 验证网络课程平台登录失败")

                isShowingMoocError = true
                throw MoocHelper.MoocHelperError.notLoggedIn
            }
        }

        moocLoginTask = task
        defer { moocLoginTask = nil }
        try await task.value
    }
}

extension AuthManager {
    func allLoginAsync() async throws {
        async let edu: () = educationLoginAsync()
        async let mooc: () = moocLoginAsync()
        _ = try await (edu, mooc)
    }

    func allLogin() {
        Task {
            do {
                try await allLoginAsync()
            } catch {
                Logger.authManager.warning("后台静默登录子系统失败: \(error)")
            }
        }
    }

    func ssoRelogin() {
        Task {
            do {
                try await ssoReloginAsync()
                allLogin()
            } catch {
                PlanetService.auth.clearToken()
                Logger.authManager.error("ssoRelogin 失败: \(error)")
            }
        }
    }

    func educationLogin() {
        Task {
            do {
                try await educationLoginAsync()
            } catch {
                Logger.authManager.error("educationLogin 失败: \(error)")
            }
        }
    }

    func moocLogin() {
        Task {
            do {
                try await moocLoginAsync()
            } catch {
                Logger.authManager.error("moocLogin 失败: \(error)")
            }
        }
    }
}
