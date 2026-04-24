//
//  WebViewCoordinator.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import Foundation
import WebKit

#if os(macOS)
import AppKit
#endif

private let downloadableMIMETypes: Set<String> = [
    "application/msword",
    "application/vnd.ms-excel",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.oasis.opendocument.presentation",
    "application/vnd.oasis.opendocument.spreadsheet",
    "application/vnd.oasis.opendocument.text",
]

private let downloadableFileExtensions: Set<String> = [
    "doc",
    "docx",
    "odp",
    "ods",
    "odt",
    "ppt",
    "pptx",
    "xls",
    "xlsx",
]

final class WebViewCoordinator: NSObject, WKUIDelegate {
    weak var controller: WebViewController?
    var lastRequestedURL: URL?

    private var currentDownloadObservation: NSKeyValueObservation?
    private var currentDownloadID: UUID?
    private var currentDownloadDestinationURL: URL?
    private var currentDownloadFilename: String?
    private var suppressNextCancelledDownloadError = false

    init(controller: WebViewController?) {
        self.controller = controller
    }

    deinit {
        currentDownloadObservation?.invalidate()
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }

        if let url = navigationAction.request.url {
            lastRequestedURL = url
            webView.load(URLRequest(url: url))
        } else {
            lastRequestedURL = nil
            webView.load(navigationAction.request)
        }

        return nil
    }

    #if os(macOS)
    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping ([URL]?) -> Void
    ) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = parameters.allowsDirectories
        openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection

        let completeSelection: (NSApplication.ModalResponse) -> Void = { response in
            completionHandler(response == .OK ? openPanel.urls : nil)
        }

        if let window = webView.window {
            openPanel.beginSheetModal(for: window, completionHandler: completeSelection)
        } else {
            completeSelection(openPanel.runModal())
        }
    }
    #endif
}

extension WebViewCoordinator {
    fileprivate func shouldDownload(_ navigationResponse: WKNavigationResponse) -> Bool {
        if !navigationResponse.canShowMIMEType {
            return true
        }

        let response = navigationResponse.response

        if let contentDisposition = contentDispositionHeader(in: response as? HTTPURLResponse)?.lowercased(),
            contentDisposition.contains("attachment")
        {
            return true
        }

        if let mimeType = response.mimeType?.lowercased(),
            downloadableMIMETypes.contains(mimeType)
        {
            return true
        }

        if let suggestedFilename = response.suggestedFilename?.lowercased(),
            downloadableFileExtensions.contains(URL(fileURLWithPath: suggestedFilename).pathExtension)
        {
            return true
        }

        if let pathExtension = response.url?.pathExtension.lowercased(),
            downloadableFileExtensions.contains(pathExtension)
        {
            return true
        }

        return false
    }

    fileprivate func contentDispositionHeader(in response: HTTPURLResponse?) -> String? {
        response?.value(forHTTPHeaderField: "Content-Disposition")
    }

    fileprivate func resolvedDownloadFilename(response: URLResponse, suggestedFilename: String) -> String {
        let fallbackFilename = sanitizeDownloadFilename(suggestedFilename)

        guard let httpResponse = response as? HTTPURLResponse,
            let contentDisposition = contentDispositionHeader(in: httpResponse)
        else {
            return fallbackFilename
        }

        let headerFilename =
            filenameFromContentDisposition(contentDisposition, key: "filename*")
            ?? filenameFromContentDisposition(contentDisposition, key: "filename")

        guard let headerFilename else {
            return fallbackFilename
        }

        var filename = sanitizeDownloadFilename(headerFilename)
        let fallbackExtension = URL(fileURLWithPath: fallbackFilename).pathExtension

        if !fallbackExtension.isEmpty && URL(fileURLWithPath: filename).pathExtension.isEmpty {
            filename += ".\(fallbackExtension)"
        }

        return filename
    }

    fileprivate func filenameFromContentDisposition(_ header: String, key: String) -> String? {
        let lowercasePrefix = "\(key.lowercased())="

        for rawSegment in header.split(separator: ";", omittingEmptySubsequences: true) {
            let segment = rawSegment.trimmingCharacters(in: .whitespacesAndNewlines)
            guard segment.lowercased().hasPrefix(lowercasePrefix) else { continue }

            var value = String(segment.dropFirst(key.count + 1))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))

            if key == "filename*", let encodedValueRange = value.range(of: "''") {
                value = String(value[encodedValueRange.upperBound...])
            }

            return value.removingPercentEncoding ?? value
        }

        return nil
    }

    fileprivate func sanitizeDownloadFilename(_ filename: String) -> String {
        let decodedFilename = filename.removingPercentEncoding ?? filename
        let trimmedFilename = decodedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let sanitizedFilename =
            trimmedFilename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "-")

        return sanitizedFilename.isEmpty ? "download" : sanitizedFilename
    }

    fileprivate func configureDownload(_ download: WKDownload) {
        currentDownloadObservation?.invalidate()
        currentDownloadObservation = nil
        currentDownloadID = UUID()
        currentDownloadDestinationURL = nil
        currentDownloadFilename = nil
        suppressNextCancelledDownloadError = false
        download.delegate = self
    }

    fileprivate func startObservingProgress(for download: WKDownload) {
        currentDownloadObservation?.invalidate()
        currentDownloadObservation = download.progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
            guard let self,
                let filename = self.currentDownloadFilename,
                let downloadID = self.currentDownloadID
            else {
                return
            }

            Task { @MainActor [weak self] in
                guard let self, self.currentDownloadID == downloadID else { return }
                self.controller?.updateDownloadProgress(filename: filename, progress: progress)
            }
        }
    }

    fileprivate func resetDownloadState() {
        currentDownloadObservation?.invalidate()
        currentDownloadObservation = nil
        currentDownloadID = nil
        currentDownloadDestinationURL = nil
        currentDownloadFilename = nil
        suppressNextCancelledDownloadError = false
    }

    fileprivate func uniqueDownloadURL(for filename: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseName = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let fileExtension = URL(fileURLWithPath: filename).pathExtension
        var candidateURL = directory.appendingPathComponent(filename)
        var suffix = 1

        while fileManager.fileExists(atPath: candidateURL.path) {
            let nextFilename: String
            if fileExtension.isEmpty {
                nextFilename = "\(baseName)-\(suffix)"
            } else {
                nextFilename = "\(baseName)-\(suffix).\(fileExtension)"
            }

            candidateURL = directory.appendingPathComponent(nextFilename)
            suffix += 1
        }

        return candidateURL
    }

    fileprivate func beginDownload(named filename: String) {
        Task { @MainActor [weak self] in
            self?.controller?.beginDownload(filename: filename)
        }
    }

    fileprivate func finishDownload(at url: URL) {
        Task { @MainActor [weak self] in
            self?.controller?.finishDownload(at: url)
        }
    }

    fileprivate func failDownload(_ error: Error) {
        Task { @MainActor [weak self] in
            self?.controller?.failDownload(error)
        }
    }

    #if os(macOS)
    fileprivate func presentSavePanel(
        for download: WKDownload,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.canSelectHiddenExtension = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = suggestedFilename

        let finishSelection: (URL?) -> Void = { [weak self] destinationURL in
            guard let self else {
                completionHandler(nil)
                return
            }

            guard let destinationURL else {
                self.suppressNextCancelledDownloadError = true
                completionHandler(nil)
                return
            }

            let selectedFilename = destinationURL.lastPathComponent
            self.currentDownloadFilename = selectedFilename
            self.currentDownloadDestinationURL = destinationURL
            self.beginDownload(named: selectedFilename)
            self.startObservingProgress(for: download)
            completionHandler(destinationURL)
        }

        if let webView = download.webView, let window = webView.window {
            savePanel.beginSheetModal(for: window) { response in
                finishSelection(response == .OK ? savePanel.url : nil)
            }
        } else {
            finishSelection(savePanel.runModal() == .OK ? savePanel.url : nil)
        }
    }
    #endif
}

extension WebViewCoordinator: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if #available(macOS 11.3, iOS 14.5, *), navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if #available(macOS 11.3, iOS 14.5, *), shouldDownload(navigationResponse) {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        controller?.syncState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        controller?.syncState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        controller?.syncState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        controller?.syncState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        controller?.syncState()
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        configureDownload(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        configureDownload(download)
    }
}

extension WebViewCoordinator: WKDownloadDelegate {
    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let resolvedFilename = resolvedDownloadFilename(response: response, suggestedFilename: suggestedFilename)

        #if os(macOS)
        presentSavePanel(for: download, suggestedFilename: resolvedFilename, completionHandler: completionHandler)
        #else
        let destinationURL = uniqueDownloadURL(for: resolvedFilename, in: FileManager.default.temporaryDirectory)
        currentDownloadFilename = resolvedFilename
        currentDownloadDestinationURL = destinationURL
        beginDownload(named: resolvedFilename)
        startObservingProgress(for: download)
        completionHandler(destinationURL)
        #endif
    }

    func download(
        _ download: WKDownload,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        decisionHandler: @escaping (WKDownload.RedirectPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }

    func download(
        _ download: WKDownload,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destinationURL = currentDownloadDestinationURL else {
            resetDownloadState()
            return
        }

        resetDownloadState()
        finishDownload(at: destinationURL)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let nsError = error as NSError
        let shouldSuppressError =
            suppressNextCancelledDownloadError
            && nsError.domain == NSURLErrorDomain
            && nsError.code == NSURLErrorCancelled

        resetDownloadState()

        if !shouldSuppressError {
            failDownload(error)
        }
    }
}
