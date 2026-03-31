//
//  OnboardingPlaceholderPage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingPlaceholderPage: View {
    var body: some View {
        ContentUnavailableView {
            Label("页面占位", systemImage: "square.dashed")
        } description: {
            Text("中间页面占位")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    OnboardingPlaceholderPage()
        .padding()
}
