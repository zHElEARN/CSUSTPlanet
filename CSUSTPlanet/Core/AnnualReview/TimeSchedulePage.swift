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
    @State private var showRhythmStats = false  // 早晚课
    @State private var showWeekendStats = false  // 周末

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let cardBg = Color(hex: "1C1C1E")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")
    private let warningColor = Color(hex: "FFD60A")  // 用于周末，表示一种警示或特殊

    // 布局常量
    private let barHeight: CGFloat = 36

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (时间雷达)
            ZStack {
                // 外圈刻度
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 15]))
                    .foregroundColor(textSecondary.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .rotationEffect(.degrees(showHeroStats ? 360 : 0))  // 极慢的旋转动画
                    .animation(.linear(duration: 60).repeatForever(autoreverses: false), value: showHeroStats)

                // 内圈实线
                Circle()
                    .stroke(textSecondary.opacity(0.05), lineWidth: 20)
                    .frame(width: 220, height: 220)
            }
            .offset(y: -50)  // 略微上移，作为背景衬托
            .opacity(showHeroStats ? 1 : 0)

            // 3. 内容层
            VStack(spacing: 0) {

                // --- 顶部索引 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 02")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("TIME INVESTMENT")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("课程时间投入统计")
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

                    Text("MINUTES / 累计课堂专注时长")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accentColor)
                        .tracking(1)

                    // 辅助数据：总课程数
                    HStack(spacing: 4) {
                        Text("本年度共计修读")
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

                // --- 昼夜节律 (早八 vs 晚课) ---
                VStack(alignment: .leading, spacing: 24) {

                    // 标题
                    Text("DAILY RHYTHM / 昼夜节律分布")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(textSecondary)
                        .tracking(1)

                    VStack(spacing: 16) {
                        // 早八数据条
                        TimeBarView(
                            timeLabel: "08:00",
                            descLabel: "早八课程出席次数",
                            count: data.earlyMorningCoursesCount,
                            totalReference: max(data.earlyMorningCoursesCount, data.eveningCoursesCount),
                            color: textPrimary,
                            isAnimated: showRhythmStats
                        )

                        // 晚课数据条
                        TimeBarView(
                            timeLabel: "19:30",
                            descLabel: "夜间课程出席次数",
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

                // --- 周末数据 (底部) ---
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEEKEND OVERTIME")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(warningColor)

                        Text("周末双休占用课程次数")
                            .font(.system(size: 14))
                            .foregroundStyle(textSecondary)
                    }

                    Spacer()

                    Text("\(data.weekendCoursesCount)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(warningColor)
                }
                .padding(24)
                .background(Color.white.opacity(0.05))  // 极淡的背景块
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(warningColor.opacity(0.3)),
                    alignment: .top
                )
                .opacity(showWeekendStats ? 1 : 0)
                .offset(y: showWeekendStats ? 0 : 30)
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

        // 1. 标题
        withAnimation(.easeOut(duration: 0.5)) {
            showHeader = true
        }

        // 2. 核心大数字 + 背景雷达
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showHeroStats = true
        }

        // 3. 进度条生长
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.5)) {
            showRhythmStats = true
        }

        // 4. 底部周末数据
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showWeekendStats = true
        }

        // 5. 解锁
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
    let totalReference: Int  // 用于计算进度条长度的参考最大值
    let color: Color
    let isAnimated: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 时间戳
            Text(timeLabel)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 50, alignment: .leading)

            // 进度条与描述
            VStack(alignment: .leading, spacing: 6) {
                // 条形图
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // 轨道
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // 实体
                        Capsule()
                            .fill(color)
                            .frame(width: isAnimated ? calculateWidth(geo.size.width) : 0, height: 8)
                    }
                }
                .frame(height: 8)

                // 文字描述
                HStack {
                    Text(descLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "8E8E93"))

                    Spacer()

                    Text("\(count) 次")
                        .font(.system(size: 14, weight: .bold))  // 强调次数
                        .foregroundStyle(Color(hex: "FFFFFF"))
                }
            }
        }
    }

    // 计算宽度：即使数量很少，也给一点基础宽度可见
    private func calculateWidth(_ totalWidth: CGFloat) -> CGFloat {
        if totalReference == 0 { return 0 }
        let ratio = CGFloat(count) / CGFloat(max(totalReference, 1))  // 防止除以0，虽然max已经处理
        // 简单线性比例，最大占满
        return totalWidth * ratio
    }
}
