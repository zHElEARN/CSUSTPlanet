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
                headerSection
                previewImage
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            Text("桌面小组件")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("把课表、成绩、待提交作业和宿舍电量等信息放到桌面上，不打开 App 也能快速查看常用校园信息。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    private var previewImage: some View {
        VStack(spacing: 16) {
            Image("onboarding_widget_preview")
                .resizable()
                .scaledToFit()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }
}
