//
//  OnboardingPlaceholderPage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingPlaceholderPage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                placeholderCard
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.dashed")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            Text("页面占位")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("中间页面占位")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var placeholderCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("当前页面内容暂未配置。")
                    .font(.headline)

                Text("结构与其它 Onboarding 页面保持一致。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
    }
}
