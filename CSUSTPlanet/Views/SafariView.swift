//
//  SafariView.swift
//  CSUSTPlanet
//
//  Created by liuzeyun on 2025/9/9.
//

import SwiftUI
import WebKit

#if canImport(SafariServices)
import SafariServices
#endif

#if os(macOS)
struct SafariView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}
#else
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif
