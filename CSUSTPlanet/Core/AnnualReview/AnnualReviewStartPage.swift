//
//  AnnualReviewStartPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct AnnualReviewStartPage: View {
    // MARK: - External Controls
    /// 是否开始动画
    var startAnimation: Bool
    /// 动画结束回调（用于解锁外部滚动）
    var onAnimationEnd: () -> Void

    // MARK: - Internal Animation States
    @State private var hasAnimated = false

    @State private var showGrid = false
    @State private var showDecor = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showArrow = false

    // MARK: - Constants (Fixed Palette)
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg
                .ignoresSafeArea()

            // 背景装饰：网格线条 (透明度已调高至 0.12 以确保可见)
            GridBackground()
                .opacity(showGrid ? 0.12 : 0)
                .mask(
                    LinearGradient(
                        colors: [.black, .black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack {
                // 顶部装饰：档案编号
                HStack {
                    Text("NO.CSUST-DATA-2025")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(textSecondary)
                        .tracking(2)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .offset(y: showDecor ? 0 : -20)
                .opacity(showDecor ? 1 : 0)

                Spacer()

                // 中间核心文字区
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("2025")
                            .font(.system(size: 88, weight: .heavy))
                            .foregroundStyle(textPrimary)
                            .tracking(-3)  // 紧凑排版
                            .lineLimit(1)

                        Text(".")
                            .font(.system(size: 88, weight: .heavy))
                            .foregroundStyle(accentColor)
                    }
                    // 核心动画：缩放 + 模糊消除 (不循环)
                    .scaleEffect(showTitle ? 1 : 0.8)
                    .opacity(showTitle ? 1 : 0)
                    .blur(radius: showTitle ? 0 : 10)

                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(textPrimary)
                            .frame(width: 40, height: 2)

                        Text("ANNUAL REPORT")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(textPrimary)
                            .tracking(4)

                        Rectangle()
                            .fill(textPrimary)
                            .frame(width: 40, height: 2)
                    }
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 20)

                    Text("长理星球 · 数据归档")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(textSecondary)
                        .tracking(8)
                        .padding(.top, 16)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 20)
                }

                Spacer()

                // 底部引导区
                VStack(spacing: 12) {
                    Text("SCROLL TO ACCESS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(textSecondary.opacity(0.7))

                    Image(systemName: "chevron.down")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(textPrimary)
                        // 简单的呼吸效果
                        .offset(y: showArrow ? 5 : -5)
                        .animation(
                            showArrow ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : nil,
                            value: showArrow
                        )
                }
                .padding(.bottom, 60)
                .opacity(showArrow ? 1 : 0)
            }
        }
        .onChange(of: startAnimation) { _, newValue in
            if newValue && !hasAnimated {
                performAnimation()
            }
        }
        .onAppear {
            if startAnimation && !hasAnimated {
                performAnimation()
            }
        }
    }

    // MARK: - Animation Sequence
    private func performAnimation() {
        hasAnimated = true

        // 1. 网格浮现
        withAnimation(.easeOut(duration: 0.8)) {
            showGrid = true
        }

        // 2. 顶部装饰下沉
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            showDecor = true
        }

        // 3. 2025 主标题重击感入场
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
            showTitle = true
        }

        // 4. 副标题上浮
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            showSubtitle = true
        }

        // 5. 底部箭头出现
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            showArrow = true
        }

        // 6. 动画完全结束后，通知父视图解锁滚动 (总耗时约 1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            onAnimationEnd()
        }
    }
}

// MARK: - Helpers
struct GridBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let spacing: CGFloat = 30  // 网格密度

                for y in stride(from: 0, to: height, by: spacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }

                for x in stride(from: 0, to: width, by: spacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .stroke(Color(hex: "FFFFFF"), lineWidth: 0.5)  // 线条颜色纯白，通过 opacity 控制显隐
        }
    }
}

#Preview {
    AnnualReviewStartPage(startAnimation: true, onAnimationEnd: {})
}
