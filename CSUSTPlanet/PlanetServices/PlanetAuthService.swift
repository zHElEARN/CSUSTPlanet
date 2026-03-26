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

@MainActor
final class PlanetAuthService {
    static let shared = PlanetAuthService()

    private init() {}

    var authToken: String?

    private let refreshLeadTime: TimeInterval = 8 * 60 * 60
    private let targetCookieName = "WISCPSID"
    private let targetCookieDomain = "ehall.csust.edu.cn"

    private enum PlanetAuthError: Error {
        case missingCookie
        case studentIDMismatch(expected: String, actual: String)
    }

    private struct AuthLoginRequest: Encodable {
        let token: String
    }

    private struct AuthLoginResponse: Decodable {
        let token: String
    }

    // MARK: - Core Methods

    func authenticate(with ssoAccount: String, session: Session) async {
        do {
            let wiscpsid = try readWISCPSIDCookieValue(session: session)
            let response = try await requestBackendToken(wiscpsid: wiscpsid)
            let newToken = response.token

            guard let studentID = getStudentID(from: newToken) else {
                Logger.planetAuthService.error("后端下发的Token缺失student_id字段")
                return
            }

            if studentID == ssoAccount {
                self.authToken = newToken
                MMKVHelper.PlanetService.authToken = newToken
                Logger.planetAuthService.info("后端认证成功，Token已保存")
            } else {
                Logger.planetAuthService.error("后端下发的Token身份不匹配。期望: \(ssoAccount)，实际: \(studentID)")
            }
        } catch {
            Logger.planetAuthService.error("后端认证失败（静默处理）: \(error)")
        }
    }

    func checkAndRefreshAuthToken(ssoAccount: String, session: Session) async {
        self.authToken = nil

        guard let cachedToken = MMKVHelper.PlanetService.authToken else {
            Logger.planetAuthService.debug("本地无缓存的Token，尝试重新获取")
            await authenticate(with: ssoAccount, session: session)
            return
        }

        guard let studentID = getStudentID(from: cachedToken), studentID == ssoAccount else {
            Logger.planetAuthService.warning("本地缓存的Token student_id与当前登录账号不一致，清理并重新获取")
            MMKVHelper.PlanetService.authToken = nil
            await authenticate(with: ssoAccount, session: session)
            return
        }

        guard let expDate = jwtExpirationDate(token: cachedToken) else {
            Logger.planetAuthService.warning("无法解析本地Token的过期时间，清理并重新获取")
            MMKVHelper.PlanetService.authToken = nil
            await authenticate(with: ssoAccount, session: session)
            return
        }

        let now = Date()
        if expDate <= now {
            Logger.planetAuthService.info("本地Token已完全过期，清理并重新获取")
            MMKVHelper.PlanetService.authToken = nil
            await authenticate(with: ssoAccount, session: session)
            return
        }

        self.authToken = cachedToken
        Logger.planetAuthService.info("本地Token验证通过，已加载到内存")

        let timeRemaining = expDate.timeIntervalSince(now)
        if timeRemaining < refreshLeadTime {
            Logger.planetAuthService.info("Token距离过期不足8小时，发起静默续期")
            await authenticate(with: ssoAccount, session: session)
        }
    }

    func clearToken() {
        self.authToken = nil
        MMKVHelper.PlanetService.authToken = nil
        Logger.planetAuthService.info("Token已清空")
    }

    // MARK: - Private Helpers

    private func requestBackendToken(wiscpsid: String) async throws -> AuthLoginResponse {
        return try await AF.request(
            "\(Constants.backendHost)/auth/login",
            method: .post,
            parameters: AuthLoginRequest(token: wiscpsid),
            encoder: JSONParameterEncoder.default
        )
        .serializingDecodable(AuthLoginResponse.self)
        .value
    }

    private func readWISCPSIDCookieValue(session: Session) throws -> String {
        guard let cookies = session.sessionConfiguration.httpCookieStorage?.cookies else {
            throw PlanetAuthError.missingCookie
        }

        guard
            let cookie = cookies.first(where: { cookie in
                let normalizedDomain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
                return cookie.name == targetCookieName && normalizedDomain == targetCookieDomain
            }),
            !cookie.value.isEmpty
        else {
            throw PlanetAuthError.missingCookie
        }

        return cookie.value
    }

    private func jwtExpirationDate(token: String) -> Date? {
        do {
            let jwt = try decode(jwt: token)
            return jwt.expiresAt
        } catch {
            return nil
        }
    }

    private func getStudentID(from token: String) -> String? {
        do {
            let jwt = try decode(jwt: token)
            return jwt.claim(name: "student_id").string
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
