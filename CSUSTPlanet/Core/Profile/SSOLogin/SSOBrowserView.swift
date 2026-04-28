//
//  SSOBrowserView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/9.
//

import CSUSTKit
import SwiftUI
import WebKit

struct SSOBrowserView: PlatformViewRepresentable {
    enum LoginMode {
        case username
        case dynamic
    }

    var onSuccess: (String, String, LoginMode, [HTTPCookie]) -> Void

    static let factory = URLFactory(mode: AuthManager.shared.mode)

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var username: String = KeychainUtil.ssoUsername ?? ""
        var password: String = KeychainUtil.ssoPassword ?? ""
        var loginMode: LoginMode = .username

        let onSuccess: (String, String, LoginMode, [HTTPCookie]) -> Void

        init(onSuccess: @escaping (String, String, LoginMode, [HTTPCookie]) -> Void) {
            self.onSuccess = onSuccess
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let injectionScript = """
                document.getElementById('username').value = '\(username)';
                document.getElementById('password').value = '\(password)';
                """
            webView.evaluateJavaScript(injectionScript)

            let observationScript = """
                (function() {
                    function watchInput(id, fieldName) {
                        const input = document.getElementById(id);
                        if (!input) return;
                        const sendValue = () => {
                            window.webkit.messageHandlers.fieldChanged.postMessage({
                                field: fieldName,
                                value: input.value
                            });
                        };
                        input.addEventListener('input', sendValue);
                        const observer = new MutationObserver(sendValue);
                        observer.observe(input, { attributes: true, attributeFilter: ['value'] });
                    }
                    watchInput('username', 'username');
                    watchInput('password', 'password');
                })();
                """
            webView.evaluateJavaScript(observationScript)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.absoluteString.contains("login?type=userNameLogin") {
                loginMode = .username
            } else if url.absoluteString.contains("login?type=dynamicLogin") {
                loginMode = .dynamic
            }

            if url == URL(string: factory.make(.ehall, "/index.html")) || url == URL(string: factory.make(.ehall, "/default/index.html")) {
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                    guard let self else { return }
                    onSuccess(username, password, loginMode, cookies)
                }
            }
            decisionHandler(.allow)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "fieldChanged",
                let body = message.body as? [String: String],
                let field = body["field"],
                let value = body["value"]
            {
                switch field {
                case "username":
                    self.username = value
                case "password":
                    self.password = value
                default:
                    break
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess)
    }

    private func makeWebView(coordinator: Coordinator) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(coordinator, name: "fieldChanged")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.load(URLRequest(url: URL(string: Self.factory.make(.authServer, "/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin"))!))

        return webView
    }

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    #endif

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
    #endif
}
