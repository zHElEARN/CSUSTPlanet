//
//  WebView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI
import WebKit

#if os(macOS)
private typealias PlatformViewRepresentable = NSViewRepresentable
#else
private typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct WebView: PlatformViewRepresentable {
    let url: URL
    let cookies: [HTTPCookie]?

    init(url: URL, cookies: [HTTPCookie]? = nil) {
        self.url = url
        self.cookies = cookies
    }

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        return createWebView(context: context)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateWebView(nsView, context: context)
    }
    #endif

    #if os(iOS) || os(visionOS)
    func makeUIView(context: Context) -> WKWebView {
        return createWebView(context: context)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateWebView(uiView, context: context)
    }
    #endif

    private func createWebView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.nonPersistent()

        if let cookies = cookies {
            let cookieStore = dataStore.httpCookieStore
            for cookie in cookies {
                cookieStore.setCookie(cookie)
            }
        }

        configuration.websiteDataStore = dataStore
        let webView = WKWebView(frame: .zero, configuration: configuration)

        return webView
    }

    private func updateWebView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
