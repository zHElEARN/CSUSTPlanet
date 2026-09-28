//
//  WebViewRepresentable.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import OSLog
import SwiftUI
import WebKit

struct WebViewRepresentable: PlatformViewRepresentable {
    let url: URL
    let cookies: [HTTPCookie]?
    let controller: WebViewController?

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(controller: controller)
    }

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        createWebView(context: context)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        updateWebView(nsView, context: context)
    }
    #endif

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        createWebView(context: context)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        updateWebView(uiView, context: context)
    }
    #endif

    private func createWebView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let dataStore = WKWebsiteDataStore.nonPersistent()
        configuration.websiteDataStore = dataStore

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        context.coordinator.controller = controller
        controller?.webView = webView
        controller?.syncState()

        let cookies = cookies ?? []
        let cookieStore = dataStore.httpCookieStore

        Task { @MainActor in
            Logger.webView.debug("开始向 WKWebView 注入 \(cookies.count) 个 Cookie")
            await cookieStore.setCookies(cookies)
            Logger.webView.debug("WKWebView Cookie 注入完成，开始加载 \(url.absoluteString, privacy: .public)")
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    private func updateWebView(_ webView: WKWebView, context: Context) {
        context.coordinator.controller = controller
        controller?.webView = webView
    }
}
