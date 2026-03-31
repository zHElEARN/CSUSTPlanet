//
//  OnboardingCompletionPage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingCompletionPage: View {
    var body: some View {
        ContentUnavailableView {
            Label("配置完成", systemImage: "checkmark.circle")
        } description: {
            Text("结束页面占位，可以开始使用 App 了")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingCompletionPage()
        .padding()
}
