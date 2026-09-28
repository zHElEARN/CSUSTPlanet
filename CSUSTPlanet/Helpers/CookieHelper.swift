//
//  CookieHelper.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/16.
//

import Alamofire
import CSUSTKit
import Foundation

final class CookieHelper {
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"

    static let shared = CookieHelper()

    let session: Session

    private init() {
        let configuration = URLSessionConfiguration.default
        var additionalHeaders = configuration.httpAdditionalHeaders ?? [:]
        additionalHeaders["User-Agent"] = Self.userAgent
        configuration.httpAdditionalHeaders = additionalHeaders

        if let data = KeychainUtil.cookies {
            if let cookies = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data) as? [HTTPCookie] {
                for cookie in cookies {
                    configuration.httpCookieStorage?.setCookie(cookie)
                }
            }
        }
        self.session = Session(
            configuration: configuration,
            interceptor: EduHelper.EduRequestInterceptor(maxRetryCount: 5)
        )
    }

    func clearCookies() {
        if let storage = session.sessionConfiguration.httpCookieStorage {
            if let cookies = storage.cookies {
                for cookie in cookies {
                    storage.deleteCookie(cookie)
                }
            }
        }
        KeychainUtil.cookies = nil
    }

    func updateCookies(_ cookies: [HTTPCookie]) {
        guard let storage = session.sessionConfiguration.httpCookieStorage else { return }
        cookies.forEach { storage.setCookie($0) }
    }

    var currentCookies: [HTTPCookie] {
        session.sessionConfiguration.httpCookieStorage?.cookies ?? []
    }

    func save() {
        guard let cookies = session.sessionConfiguration.httpCookieStorage?.cookies else { return }
        let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: true)
        KeychainUtil.cookies = data
    }
}
