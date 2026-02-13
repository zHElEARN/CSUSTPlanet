//
//  DormPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct DormPage: View {
    // MARK: - Data Input
    let data: AnnualReviewData

    // MARK: - Animation Controls
    var startAnimation: Bool
    var onAnimationEnd: () -> Void

    // MARK: - Internal States
    @State private var hasAnimated = false
    @State private var showHeader = false
    @State private var showRoomCard = false
    @State private var showStats = false
    @State private var showExtremes = false

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let electricYellow = Color(hex: "FFD60A")  // 专属电量黄
    private let cardBg = Color(hex: "1C1C1E")

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (电路轨迹)
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                Path { path in
                    // 模拟电路板走线
                    path.move(to: CGPoint(x: w * 0.2, y: 0))
                    path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.3))
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.3))  // 横向折线
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.7))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.7))
                    path.addLine(to: CGPoint(x: w * 0.5, y: h))
                }
                .stroke(electricYellow.opacity(0.15), style: StrokeStyle(lineWidth: 2, lineCap: .square, dash: [10, 10]))

                // 装饰节点
                Circle()
                    .fill(electricYellow.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .position(x: w * 0.8, y: h * 0.3)
                    .blur(radius: 30)
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部索引 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 06")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(electricYellow)
                        .tracking(2)

                    Text("DORMITORY LIFE")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("校园生活空间")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

                Spacer()

                if let stat = data.dormElectricityStats.first {
                    // --- 核心：门牌号卡片 ---
                    VStack(spacing: 0) {
                        // 顶部装饰条
                        Rectangle()
                            .fill(electricYellow)
                            .frame(height: 4)

                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .foregroundStyle(textSecondary)
                                Spacer()
                                Text(stat.campusName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(textSecondary)
                            }

                            VStack(spacing: 4) {
                                Text(stat.buildingName)
                                    .font(.system(size: 16))
                                    .foregroundStyle(textPrimary)

                                Text(stat.room)
                                    .font(.system(size: 80, weight: .heavy, design: .monospaced))  // 巨大的房间号
                                    .foregroundStyle(textPrimary)
                                    .tracking(-2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            .frame(height: 120)
                        }
                        .padding(24)
                        .background(cardBg)
                    }
                    .padding(.horizontal, 24)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .opacity(showRoomCard ? 1 : 0)
                    .scaleEffect(showRoomCard ? 1 : 0.95)

                    Spacer()

                    // --- 数据：交互行为 ---
                    HStack(spacing: 16) {
                        DormStatBox(
                            icon: "bolt.fill",
                            label: "购电充值次数",
                            value: "\(stat.chargeCount)",
                            unit: "次",
                            accent: electricYellow
                        )

                        DormStatBox(
                            icon: "magnifyingglass",
                            label: "电量关注次数",  // 替换“查询”
                            value: "\(stat.queryCount)",
                            unit: "次",
                            accent: textPrimary
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 20)

                    // --- 数据：极值记录 ---
                    VStack(alignment: .leading, spacing: 12) {
                        Text("电量波动极值记录")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(textSecondary)
                            .padding(.top, 16)

                        HStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text("历史最高剩余")
                                    .font(.system(size: 10))
                                    .foregroundStyle(textSecondary)
                                Text(String(format: "%.1f", stat.maxElectricity))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundStyle(textPrimary)
                                Text("度")
                                    .font(.system(size: 10))
                                    .foregroundStyle(textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // 简单的视觉分割
                            Rectangle()
                                .fill(textSecondary.opacity(0.2))
                                .frame(width: 1, height: 30)

                            VStack(alignment: .leading) {
                                Text("历史最低剩余")  // 很有危机感的数据
                                    .font(.system(size: 10))
                                    .foregroundStyle(textSecondary)
                                Text(String(format: "%.1f", stat.minElectricity))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundStyle(electricYellow)  // 低电量用黄色标示
                                Text("度")
                                    .font(.system(size: 10))
                                    .foregroundStyle(textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 24)
                        }
                        .padding(20)
                        .background(cardBg)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .opacity(showExtremes ? 1 : 0)
                    .offset(y: showExtremes ? 0 : 20)

                } else {
                    // 无数据状态
                    VStack {
                        Image(systemName: "house.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(textSecondary.opacity(0.5))
                        Text("暂无宿舍绑定信息")
                            .font(.system(size: 14))
                            .foregroundStyle(textSecondary)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 100)
                    .opacity(showRoomCard ? 1 : 0)
                }
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

        withAnimation(.easeOut(duration: 0.5)) {
            showHeader = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showRoomCard = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showStats = true
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            showExtremes = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onAnimationEnd()
        }
    }
}

// MARK: - Subviews

struct DormStatBox: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: "FFFFFF"))

                HStack(spacing: 2) {
                    Text(label)
                    Text(unit)
                }
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "8E8E93"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
    }
}
