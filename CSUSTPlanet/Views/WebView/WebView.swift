//
//  WebView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import Foundation
import SwiftUI

struct WebView: View {
    let url: URL
    let cookies: [HTTPCookie]?
    let controller: WebViewController?

    @State private var fallbackController = WebViewController()

    init(url: URL, cookies: [HTTPCookie]? = nil, controller: WebViewController? = nil) {
        self.url = url
        self.cookies = cookies
        self.controller = controller
    }

    private var resolvedController: WebViewController {
        controller ?? fallbackController
    }

    private var isShowingAlert: Binding<Bool> {
        Binding(
            get: { resolvedController.alertState != nil },
            set: { isPresented in
                if !isPresented {
                    resolvedController.dismissAlert()
                }
            }
        )
    }

    private var successToastBinding: Binding<ToastState> {
        Binding(
            get: { resolvedController.successToast },
            set: { resolvedController.successToast = $0 }
        )
    }

    #if os(iOS)
    private var isShowingShareSheet: Binding<Bool> {
        Binding(
            get: { resolvedController.pendingSharedDownload != nil },
            set: { isPresented in
                if !isPresented {
                    resolvedController.completeSharedDownloadPresentation()
                }
            }
        )
    }
    #endif

    var body: some View {
        let controller = resolvedController

        WebViewRepresentable(url: url, cookies: cookies, controller: controller)
            .overlay(alignment: .bottom) {
                if let downloadState = controller.downloadState {
                    WebViewDownloadOverlay(downloadState: downloadState)
                        .padding()
                        .allowsHitTesting(false)
                }
            }
            .alert(
                controller.alertState?.title ?? "",
                isPresented: isShowingAlert,
                presenting: controller.alertState
            ) { _ in
                Button("确定", role: .cancel) {
                    controller.dismissAlert()
                }
            } message: { alertState in
                Text(alertState.message)
            }
            .successToast(successToastBinding)
            #if os(iOS)
        .sheet(isPresented: isShowingShareSheet) {
            if let sharedDownload = controller.pendingSharedDownload {
                ShareSheet(items: [sharedDownload.url])
            }
        }
            #endif
    }
}

private struct WebViewDownloadOverlay: View {
    let downloadState: WebViewController.DownloadState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(downloadState.filename)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            if let progress = downloadState.progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
            }
        }
        .padding(12)
        .frame(maxWidth: 320, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 8, y: 4)
    }
}
