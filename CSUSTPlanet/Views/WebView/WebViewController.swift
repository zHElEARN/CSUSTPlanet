//
//  WebViewController.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI
import WebKit

@MainActor
@Observable
final class WebViewController {
    struct DownloadState {
        let filename: String
        let progress: Double?
    }

    struct AlertState {
        let title: String
        let message: String
    }

    #if os(iOS)
    struct SharedDownload {
        let url: URL
    }
    #endif

    var canGoBack = false
    var canGoForward = false
    var isLoading = false
    var title: String?
    var currentURL: URL?
    var downloadState: DownloadState?
    var alertState: AlertState?
    var successToast: ToastState = .successTitle

    #if os(iOS)
    var pendingSharedDownload: SharedDownload?
    @ObservationIgnored private var sharedDownloadCleanupURL: URL?
    #endif

    @ObservationIgnored weak var webView: WKWebView?

    func goBack() {
        webView?.goBack()
        syncState()
    }

    func goForward() {
        webView?.goForward()
        syncState()
    }

    func reload() {
        webView?.reload()
        syncState()
    }

    func syncState() {
        guard let webView else { return }
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        title = webView.title
        currentURL = webView.url
    }

    func beginDownload(filename: String) {
        downloadState = DownloadState(filename: filename, progress: nil)
    }

    func updateDownloadProgress(filename: String, progress: Progress) {
        let resolvedProgress: Double?
        if progress.totalUnitCount > 0 {
            resolvedProgress = min(max(progress.fractionCompleted, 0), 1)
        } else {
            resolvedProgress = nil
        }

        downloadState = DownloadState(filename: filename, progress: resolvedProgress)
    }

    func finishDownload(at url: URL) {
        downloadState = nil
        successToast.show(message: "已下载：\(url.lastPathComponent)")

        #if os(iOS)
        sharedDownloadCleanupURL = url
        pendingSharedDownload = SharedDownload(url: url)
        #endif
    }

    func failDownload(_ error: Error) {
        downloadState = nil
        alertState = AlertState(title: "下载失败", message: error.localizedDescription)
    }

    func dismissAlert() {
        alertState = nil
    }

    #if os(iOS)
    func completeSharedDownloadPresentation() {
        pendingSharedDownload = nil

        if let sharedDownloadCleanupURL,
            sharedDownloadCleanupURL.path.hasPrefix(FileManager.default.temporaryDirectory.path)
        {
            try? FileManager.default.removeItem(at: sharedDownloadCleanupURL)
        }

        sharedDownloadCleanupURL = nil
    }
    #endif
}
