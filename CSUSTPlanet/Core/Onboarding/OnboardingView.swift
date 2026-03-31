//
//  OnboardingView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingView: View {
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "sparkles.rectangle.stack")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)

                Text("Onboarding 占位")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("后续引导内容可以放在这里。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()

                Button("跳过", action: onSkip)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            .navigationTitle("欢迎使用")
            .inlineToolbarTitle()
        }
    }
}
