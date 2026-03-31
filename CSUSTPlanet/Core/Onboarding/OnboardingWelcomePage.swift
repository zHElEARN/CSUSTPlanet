//
//  OnboardingWelcomePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingWelcomePage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Image("MinimalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        .padding(.top, 20)

                    HStack(spacing: 0) {
                        Text("欢迎使用")
                        Text("长理星球")
                            .foregroundColor(.accentColor)
                    }
                    .font(.system(size: 30, weight: .bold))

                    Text("让您的校园生活更便捷高效。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                VStack(spacing: 16) {
                    FeatureRow(
                        icon: "graduationcap.fill",
                        iconColor: .blue,
                        title: "学业尽在掌握",
                        description: "随时随地查询您的课表、考试成绩和考试安排。"
                    )

                    FeatureRow(
                        icon: "bolt.fill",
                        iconColor: .orange,
                        title: "宿舍用电无忧",
                        description: "实时掌握宿舍电量情况，并及时接收低电量贴心提醒。"
                    )

                    FeatureRow(
                        icon: "checklist",
                        iconColor: .green,
                        title: "作业不再遗漏",
                        description: "快速查看各科课程作业，轻松追踪每一个作业截止日期。"
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                        .frame(width: 28, alignment: .center)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
    }
}
