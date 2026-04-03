//
//  SafariView.swift
//  CSUSTPlanet
//
//  Created by liuzeyun on 2025/9/9.
//

#if os(iOS)

import SafariServices
import SwiftUI
import WebKit

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#endif
