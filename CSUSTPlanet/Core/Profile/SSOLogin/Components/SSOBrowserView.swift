//
//  SSOBrowserView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/9.
//
import SwiftUI
import WebKit

struct SSOBrowserView: View {
    enum LoginMode {
        case username
        case dynamic
    }

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loginMode: LoginMode = .username
    @Binding var isPresented: Bool
    var onLoginSuccess: (String, String, LoginMode, [HTTPCookie]) -> Void

    var body: some View {
        NavigationStack {
            BrowserRepresentable(
                username: $username,
                password: $password,
                loginMode: $loginMode,
                isPresented: $isPresented,
                onLoginSuccess: onLoginSuccess
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("网页登录")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
        }
        .trackView("SSOBrowser")
        #if os(macOS)
        .frame(minWidth: 960, minHeight: 640)
        #endif
    }
}

private struct BrowserRepresentable {
    @Binding var username: String
    @Binding var password: String
    @Binding var loginMode: SSOBrowserView.LoginMode
    @Binding var isPresented: Bool
    var onLoginSuccess: (String, String, SSOBrowserView.LoginMode, [HTTPCookie]) -> Void

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        @Binding var username: String
        @Binding var password: String
        @Binding var loginMode: SSOBrowserView.LoginMode
        @Binding var isPresented: Bool
        let onLoginSuccess: (String, String, SSOBrowserView.LoginMode, [HTTPCookie]) -> Void

        init(
            username: Binding<String>,
            password: Binding<String>,
            loginMode: Binding<SSOBrowserView.LoginMode>,
            isPresented: Binding<Bool>,
            onLoginSuccess: @escaping (String, String, SSOBrowserView.LoginMode, [HTTPCookie]) -> Void
        ) {
            _username = username
            _password = password
            _loginMode = loginMode
            _isPresented = isPresented
            self.onLoginSuccess = onLoginSuccess
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
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
            webView.evaluateJavaScript(js)
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

            if url == URL(string: "https://ehall.csust.edu.cn/index.html") || url == URL(string: "https://ehall.csust.edu.cn/default/index.html") {
                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.isPresented = false
                    }
                    onLoginSuccess(username, password, loginMode, cookies)
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

                DispatchQueue.main.async {
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
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            username: $username,
            password: $password,
            loginMode: $loginMode,
            isPresented: $isPresented,
            onLoginSuccess: onLoginSuccess
        )
    }

    private func makeWebView(coordinator: Coordinator) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(coordinator, name: "fieldChanged")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = coordinator
        webView.load(URLRequest(url: URL(string: "https://authserver.csust.edu.cn/authserver/login?service=https%3A%2F%2Fehall.csust.edu.cn%2Flogin")!))
        return webView
    }
}

#if os(iOS) || os(visionOS)
extension BrowserRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#endif

#if os(macOS)
extension BrowserRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(coordinator: context.coordinator)
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif
