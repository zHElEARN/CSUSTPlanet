//
//  AnnualReviewEndPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct AnnualReviewEndPage: View {
    // MARK: - Animation Controls
    // 即使是最后一页，也可以有简单的入场
    @State private var hasAnimated = false
    @State private var showContent = false
    @State private var showCursor = false
    @State private var showFooter = false

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (结束符)
            VStack {
                Spacer()
                // 巨大的装饰性句号或结束符
                Text("■")
                    .font(.system(size: 200))
                    .foregroundStyle(textSecondary.opacity(0.03))
                    .offset(x: 100, y: 100)
            }

            // 3. 内容层
            VStack(spacing: 0) {
                Spacer()

                // --- 核心区 ---
                VStack(spacing: 24) {
                    // 2026 + 光标
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("2026")
                            .font(.system(size: 80, weight: .heavy))
                            .foregroundStyle(textPrimary)
                            .tracking(-2)

                        // 闪烁的光标，暗示未来正在写入
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: 16, height: 60)
                            .padding(.bottom, 12)
                            .opacity(showCursor ? 1 : 0)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: showCursor
                            )
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    // 副标题
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(textSecondary)
                            .frame(width: 30, height: 1)

                        Text("SYSTEM READY / 明年见")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(textSecondary)
                            .tracking(4)

                        Rectangle()
                            .fill(textSecondary)
                            .frame(width: 30, height: 1)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }

                Spacer()

                // --- 底部 Logo ---
                VStack(spacing: 12) {
                    Image(systemName: "globe.asia.australia.fill")  // 暂用 globe 替代星球 Logo
                        .font(.system(size: 24))
                        .foregroundStyle(textPrimary.opacity(0.8))

                    Text("CSUST PLANET")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(textPrimary)
                        .tracking(2)

                    Text("长理星球")
                        .font(.system(size: 10))
                        .foregroundStyle(textSecondary)
                }
                .padding(.bottom, 60)
                .opacity(showFooter ? 1 : 0)
            }
        }
        .onAppear {
            performAnimation()
        }
    }

    // MARK: - Animation Sequence
    private func performAnimation() {
        // 简单的入场，因为用户是划到底部的，不需要太复杂的锁定逻辑
        guard !hasAnimated else { return }
        hasAnimated = true

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showContent = true
        }

        withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
            showFooter = true
        }

        // 启动光标闪烁
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCursor = true
        }
    }
}
