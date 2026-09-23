//
//  OverviewHiddenToggleButton.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/23.
//

import SwiftUI

/// 概览卡片标题右侧的隐藏开关按钮，纯图标样式
struct OverviewHiddenToggleButton: View {
    let isHidden: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isHidden ? "eye.fill" : "eye.slash.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(4)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
