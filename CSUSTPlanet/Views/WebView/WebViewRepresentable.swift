//
//  WebViewRepresentable.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

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

        if let cookies {
            let cookieStore = dataStore.httpCookieStore
            for cookie in cookies {
                cookieStore.setCookie(cookie)
            }
        }

        configuration.websiteDataStore = dataStore

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator

        context.coordinator.controller = controller
        controller?.webView = webView
        controller?.syncState()

        return webView
    }

    private func updateWebView(_ webView: WKWebView, context: Context) {
        context.coordinator.controller = controller
        controller?.webView = webView

        guard context.coordinator.lastRequestedURL != url else { return }

        context.coordinator.lastRequestedURL = url
        webView.load(URLRequest(url: url))
    }
}
