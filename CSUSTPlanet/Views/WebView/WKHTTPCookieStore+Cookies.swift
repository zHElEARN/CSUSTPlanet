//
//  WKHTTPCookieStore+Cookies.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import Foundation
import OSLog
import WebKit

extension WKHTTPCookieStore {
    /// 将给定 Cookie 全部写入当前 Cookie 存储，等待每一个写入完成后再返回
    @MainActor
    func setCookies(_ cookies: [HTTPCookie]) async {
        guard !cookies.isEmpty else { return }

        await withCheckedContinuation { continuation in
            let group = DispatchGroup()
            for cookie in cookies {
                group.enter()
                setCookie(cookie) { group.leave() }
            }
            group.notify(queue: .main) {
                continuation.resume()
            }
        }
    }
}

extension Logger {
    static let webView = Logger(appCategory: "WebView")
}
