//
//  OnboardingWidgetPage.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/31.
//

import SwiftUI

struct OnboardingWidgetPage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(.accent)
                        .padding(.top, 24)

                    Text("桌面小组件")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("把课表、成绩、待办和宿舍电量放到桌面上，不打开 App 也能快速查看常用校园信息。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                }

                Image("onboarding_widget_preview")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
