//
//  ShareSheet.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/8/30.
//

#if os(iOS)
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
