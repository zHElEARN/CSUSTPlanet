//
//  PlanetAuthService.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/24.
//

import Alamofire
import Foundation
import JWTDecode
import OSLog

enum PlanetAuthService {
    static var authToken: String? {
        get { MMKVHelper.PlanetService.authToken }
        set { MMKVHelper.PlanetService.authToken = newValue }
    }

    private static let refreshLeadTime: TimeInterval = 8 * 60 * 60
    private static let targetCookieName = "WISCPSID"
    private static let targetCookieDomain = "ehall.csust.edu.cn"

    private enum SyncTrigger: String {
        case manual = "manual"
        case automatic = "automatic"
    }

    private enum RefreshReason: String {
        case missingToken = "missing_token"
        case invalidJWT = "invalid_jwt"
        case expired = "expired"
        case expiringSoon = "expiring_soon"
    }

    private enum BackendTokenError: Error {
        case invalidBackendURL
        case missingWISCPSIDCookie
        case invalidResponseToken
        case userNameMismatch(expected: String, actual: String)
    }

    private struct BackendLoginRequest: Encodable {
        let token: String
    }

    private struct BackendLoginResponse: Decodable {
        struct Profile: Decodable {
            let userName: String
        }

        let profile: Profile
        let token: String
    }

    static func syncTokenAfterManualLogin(ssoUserName: String, session: Session) async {
        await syncToken(trigger: .manual, ssoUserName: ssoUserName, session: session)
    }

    static func syncTokenAfterAutoLoginIfNeeded(ssoUserName: String, session: Session) async {
        guard let reason = refreshReasonForCurrentToken() else {
            Logger.authManager.debug("后端 Token 刷新跳过：当前 Token 仍有效且不在最后 8 小时内")
            return
        }

        await syncToken(trigger: .automatic, ssoUserName: ssoUserName, session: session, refreshReason: reason)
    }

    static func clearToken() {
        Self.authToken = nil
    }

    private static func syncToken(
        trigger: SyncTrigger,
        ssoUserName: String,
        session: Session,
        refreshReason: RefreshReason? = nil
    ) async {
        do {
            let wiscpsid = try readWISCPSIDCookieValue(session: session)
            let response = try await requestBackendToken(wiscpsid: wiscpsid)

            let expectedUserName = ssoUserName.trimmingCharacters(in: .whitespacesAndNewlines)
            let actualUserName = response.profile.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard expectedUserName == actualUserName else {
                throw BackendTokenError.userNameMismatch(expected: expectedUserName, actual: actualUserName)
            }

            let backendToken = response.token.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !backendToken.isEmpty else {
                throw BackendTokenError.invalidResponseToken
            }

            Self.authToken = backendToken
            Logger.authManager.debug("后端 Token 刷新成功，触发方式: \(trigger.rawValue)")
        } catch {
            Logger.authManager.error("后端 Token 刷新失败，触发方式: \(trigger.rawValue), 原因: \(String(describing: refreshReason?.rawValue)), 错误: \(error)")
            handleSyncFailure(trigger: trigger, refreshReason: refreshReason)
        }
    }

    private static func handleSyncFailure(trigger: SyncTrigger, refreshReason: RefreshReason?) {
        if trigger == .manual {
            clearToken()
            return
        }

        if refreshReason == .expired || refreshReason == .invalidJWT || refreshReason == .missingToken {
            clearToken()
        }
    }

    private static func refreshReasonForCurrentToken() -> RefreshReason? {
        guard let backendToken = Self.authToken?.trimmingCharacters(in: .whitespacesAndNewlines),
            !backendToken.isEmpty
        else {
            return .missingToken
        }

        guard let expirationDate = jwtExpirationDate(token: backendToken) else {
            return .invalidJWT
        }

        let now = Date()
        if now >= expirationDate {
            return .expired
        }

        let refreshBoundary = now.addingTimeInterval(refreshLeadTime)
        if refreshBoundary >= expirationDate {
            return .expiringSoon
        }

        return nil
    }

    private static func requestBackendToken(wiscpsid: String) async throws -> BackendLoginResponse {
        let loginURLString = "\(Constants.backendHost)/auth/login"
        guard let loginURL = URL(string: loginURLString) else {
            throw BackendTokenError.invalidBackendURL
        }

        return try await AF.request(
            loginURL,
            method: .post,
            parameters: BackendLoginRequest(token: wiscpsid),
            encoder: JSONParameterEncoder.default
        )
        .serializingDecodable(BackendLoginResponse.self)
        .value
    }

    fileprivate static func readWISCPSIDCookieValue(session: Session) throws -> String {
        guard let cookies = session.sessionConfiguration.httpCookieStorage?.cookies else {
            throw BackendTokenError.missingWISCPSIDCookie
        }

        guard let cookie = cookies.first(where: isTargetWISCPSIDCookie), !cookie.value.isEmpty else {
            throw BackendTokenError.missingWISCPSIDCookie
        }

        return cookie.value
    }

    fileprivate static func isTargetWISCPSIDCookie(_ cookie: HTTPCookie) -> Bool {
        let normalizedDomain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
        return cookie.name == targetCookieName && normalizedDomain == targetCookieDomain
    }

    fileprivate static func jwtExpirationDate(token: String) -> Date? {
        do {
            let jwt = try decode(jwt: token)
            return jwt.expiresAt
        } catch {
            return nil
        }
    }
}

extension MMKVHelper {
    enum PlanetService {
        @MMKVOptionalStorage(key: "PlanetService.authToken")
        static var authToken: String?
    }
}
