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
            Label("配置完成", systemImage: "checkmark.circle.fill")
        } description: {
            Text("常用功能已经准备就绪，现在就可以开始使用长理星球了。")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingCompletionPage()
        .padding()
}
