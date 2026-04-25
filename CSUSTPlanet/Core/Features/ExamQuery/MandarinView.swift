//
//  MandarinView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct MandarinView: View {
    @State private var webViewController = WebViewController()

    var body: some View {
        WebView(
            url: URL(string: "https://zwfw.moe.gov.cn/mandarin/")!,
            controller: webViewController
        )
        .navigationTitle("普通话查询")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: { webViewController.goBack() }) {
                    Label("上一页", systemImage: "chevron.left")
                }
                .disabled(!webViewController.canGoBack)

                Button(action: { webViewController.goForward() }) {
                    Label("下一页", systemImage: "chevron.right")
                }
                .disabled(!webViewController.canGoForward)
            }

            ToolbarItem(placement: .primaryAction) {
                Button(action: { webViewController.reload() }) {
                    if webViewController.isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

#Preview {
    MandarinView()
}
