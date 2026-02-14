//
//  TimeSchedulePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct TimeSchedulePage: View {
    // MARK: - Data Input
    let data: AnnualReviewData

    // MARK: - Animation Controls
    var startAnimation: Bool
    var onAnimationEnd: () -> Void

    // MARK: - Internal States
    @State private var hasAnimated = false
    @State private var showHeader = false
    @State private var showHeroStats = false  // 总时长
    @State private var showRhythmStats = false  // 早晚分布
    @State private var showWeekendStats = false  // 周末次数

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")
    // 弱化了周末的颜色，改为淡橙色，降低对比度
    private let mutedWarningColor = Color(hex: "CCAC00")

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (时间环)
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 15]))
                    .foregroundColor(textSecondary.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(showHeroStats ? 360 : 0))
                    .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: showHeroStats)

                Circle()
                    .stroke(textSecondary.opacity(0.05), lineWidth: 20)
                    .frame(width: 220, height: 220)
            }
            .offset(y: -80)
            .opacity(showHeroStats ? 1 : 0)

            // 3. 内容层
            VStack(spacing: 0) {

                // --- 顶部标题 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 02")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("CLASS TIME")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("全学年课程时长统计")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

                Spacer()

                // --- 核心数据：总时长 ---
                VStack(spacing: 12) {
                    Text("\(data.totalStudyMinutes)")
                        .font(.system(size: 64, weight: .heavy, design: .monospaced))
                        .foregroundStyle(textPrimary)
                        .tracking(-2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text("MINUTES / 累计上课总时长")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                        .tracking(1)

                    HStack(spacing: 4) {
                        Text("共计修读")
                            .foregroundStyle(textSecondary)
                        Text("\(data.totalCoursesCount)")
                            .foregroundStyle(textPrimary)
                            .bold()
                        Text("门课程")
                            .foregroundStyle(textSecondary)
                    }
                    .font(.system(size: 14))
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .opacity(showHeroStats ? 1 : 0)
                .scaleEffect(showHeroStats ? 1 : 0.9)

                Spacer()

                // --- 早八与晚课统计 ---
                VStack(alignment: .leading, spacing: 24) {
                    Text("DISTRIBUTION / 早晚课程分布")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .tracking(1)

                    VStack(spacing: 16) {
                        TimeBarView(
                            timeLabel: "08:00",
                            descLabel: "早八课程上课次数",
                            count: data.earlyMorningCoursesCount,
                            totalReference: max(data.earlyMorningCoursesCount, data.eveningCoursesCount),
                            color: textPrimary,
                            isAnimated: showRhythmStats
                        )

                        TimeBarView(
                            timeLabel: "19:30",
                            descLabel: "晚课上课次数",
                            count: data.eveningCoursesCount,
                            totalReference: max(data.earlyMorningCoursesCount, data.eveningCoursesCount),
                            color: textPrimary.opacity(0.7),
                            isAnimated: showRhythmStats
                        )
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showRhythmStats ? 1 : 0)
                .offset(y: showRhythmStats ? 0 : 20)

                Spacer()

                // --- 周末数据 (改为非全宽卡片，位置上移) ---
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEEKEND")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(mutedWarningColor)

                        Text("周末上课次数")
                            .font(.system(size: 14))
                            .foregroundStyle(textSecondary)
                    }

                    Spacer()

                    Text("\(data.weekendCoursesCount) 次")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(textPrimary.opacity(0.9))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.bottom, 60)  // 距离底部留出空间，位置上移
                .opacity(showWeekendStats ? 1 : 0)
                .offset(y: showWeekendStats ? 0 : 20)
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

    private func performAnimation() {
        hasAnimated = true

        withAnimation(.easeOut(duration: 0.5)) {
            showHeader = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showHeroStats = true
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            showRhythmStats = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showWeekendStats = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onAnimationEnd()
        }
    }
}

// MARK: - Subviews

struct TimeBarView: View {
    let timeLabel: String
    let descLabel: String
    let count: Int
    let totalReference: Int
    let color: Color
    let isAnimated: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(timeLabel)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 50, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)  // 稍微变细一点

                        Capsule()
                            .fill(color)
                            .frame(width: isAnimated ? calculateWidth(geo.size.width) : 0, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(descLabel)
                        .font(.system(size: 11))  // 缩小描述字号
                        .foregroundStyle(Color(hex: "8E8E93"))

                    Spacer()

                    Text("\(count) 次")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "FFFFFF"))
                }
            }
        }
    }

    private func calculateWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard totalReference > 0 else { return 0 }
        let ratio = CGFloat(count) / CGFloat(totalReference)
        return totalWidth * ratio
    }
}
