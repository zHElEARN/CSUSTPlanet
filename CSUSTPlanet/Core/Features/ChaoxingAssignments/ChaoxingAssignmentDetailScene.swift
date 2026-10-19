//
//  ChaoxingAssignmentDetailScene.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import SwiftUI

#if os(macOS)
struct ChaoxingAssignmentDetailScene: Scene {
    static let windowID = "chaoxing.assignment-detail"

    var body: some Scene {
        WindowGroup("作业详情", id: Self.windowID, for: URL.self) { $detailURL in
            NavigationStack {
                if let detailURL {
                    ChaoxingAssignmentDetailView(detailURL: detailURL)
                } else {
                    ContentUnavailableView("无法打开作业页面", systemImage: "exclamationmark.triangle", description: Text("作业链接无效"))
                }
            }
            .frame(minWidth: 960, minHeight: 540)
        }
        .defaultSize(width: 1280, height: 720)
        .windowResizability(.contentMinSize)
    }
}
#endif
