//
//  ChaoxingAssignmentDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import SwiftUI

struct ChaoxingAssignmentDetailView: View {
    let detailURL: URL

    @State private var webViewController = WebViewController()

    var body: some View {
        WebView(
            url: detailURL,
            cookies: CookieHelper.shared.currentCookies,
            controller: webViewController
        )
        .navigationTitle("作业详情")
        .inlineToolbarTitle()
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}
