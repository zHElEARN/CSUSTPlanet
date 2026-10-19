//
//  ChaoxingAssignmentDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import SwiftUI
import WebKit

struct ChaoxingAssignmentDetailView: View {
    let detailURL: URL

    @State private var webViewController = WebViewController()

    private static let forceVXScript = """
        (function () {
            var el = document.getElementById('vx');
            if (el) { el.value = '1'; }
            window.vx = '1';
        })();
        """

    var body: some View {
        WebView(
            url: detailURL,
            cookies: CookieHelper.shared.currentCookies,
            controller: webViewController,
            userScripts: [
                WKUserScript(
                    source: Self.forceVXScript,
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            ]
        )
        .navigationTitle("作业详情")
        .inlineToolbarTitle()
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}
