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
    @State private var showContent = false
    @State private var selectedDormIndex = 0  // 用于切换多个宿舍

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let electricYellow = Color(hex: "FFD60A")
    private let cardBg = Color(hex: "1C1C1E")

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (电路轨迹) - 优化了走线，使其更紧凑
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: geo.size.width * 0.1, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.1, y: geo.size.height * 0.2))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.9, y: geo.size.height * 0.25))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.9, y: geo.size.height * 0.6))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.1, y: geo.size.height * 0.7))
                }
                .stroke(electricYellow.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [8, 12]))
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部标题 ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("SECTION 06")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(electricYellow)
                        .tracking(2)

                    Text("DORMITORY")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("宿舍电量与充值数据统计")
                        .font(.system(size: 13))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 50)
                .opacity(showHeader ? 1 : 0)

                if !data.dormElectricityStats.isEmpty {
                    let currentStat = data.dormElectricityStats[selectedDormIndex]

                    // --- 宿舍切换选择器 (仅在有多个宿舍时显示) ---
                    if data.dormElectricityStats.count > 1 {
                        Picker("选择宿舍", selection: $selectedDormIndex) {
                            ForEach(0..<data.dormElectricityStats.count, id: \.self) { index in
                                Text(data.dormElectricityStats[index].room).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .opacity(showContent ? 1 : 0)
                    }

                    Spacer(minLength: 20)

                    // --- 核心信息卡片 ---
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentStat.campusName)
                                    .font(.system(size: 12))
                                    .foregroundStyle(textSecondary)
                                Text(currentStat.buildingName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(textPrimary)
                            }
                            Spacer()
                            Text(currentStat.room)
                                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                                .foregroundStyle(electricYellow)
                        }

                        Divider().background(textSecondary.opacity(0.2))

                        // 数据网格
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            DormMiniStat(label: "充值次数", value: "\(currentStat.chargeCount)", unit: "次", color: electricYellow)
                            DormMiniStat(label: "查询次数", value: "\(currentStat.queryCount)", unit: "次", color: textPrimary)
                        }
                    }
                    .padding(24)
                    .background(cardBg)
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    Spacer(minLength: 20)

                    // --- 极值数据分析卡片 ---
                    VStack(alignment: .leading, spacing: 16) {
                        Text("HISTORY / 历史电量极值记录")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(textSecondary)

                        HStack(spacing: 12) {
                            // 最高电量
                            VStack(alignment: .leading, spacing: 8) {
                                Text("历史最高剩余")
                                    .font(.system(size: 11))
                                    .foregroundStyle(textSecondary)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", currentStat.maxElectricity))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundStyle(textPrimary)
                                    Text("度").font(.system(size: 10)).foregroundStyle(textSecondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(12)

                            // 最低电量
                            VStack(alignment: .leading, spacing: 8) {
                                Text("历史最低剩余")
                                    .font(.system(size: 11))
                                    .foregroundStyle(textSecondary)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", currentStat.minElectricity))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundStyle(electricYellow)
                                    Text("度").font(.system(size: 10)).foregroundStyle(textSecondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(12)
                        }
                    }
                    .padding(24)
                    .background(cardBg.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)

                } else {
                    // 无数据状态
                    VStack(spacing: 16) {
                        Image(systemName: "house.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(textSecondary.opacity(0.3))
                        Text("暂无宿舍绑定及用电信息")
                            .font(.system(size: 14))
                            .foregroundStyle(textSecondary)
                    }
                    .frame(maxHeight: .infinity)
                }

                Spacer()

                // 底部标注
                Text("数据基于 APP 内手动查询与充值记录统计")
                    .font(.system(size: 10))
                    .foregroundStyle(textSecondary.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedDormIndex)
        .onChange(of: startAnimation) { _, newValue in
            if newValue && !hasAnimated { performAnimation() }
        }
        .onAppear {
            if startAnimation && !hasAnimated { performAnimation() }
        }
    }

    private func performAnimation() {
        hasAnimated = true
        withAnimation(.easeOut(duration: 0.4)) { showHeader = true }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showContent = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onAnimationEnd()
        }
    }
}

// MARK: - Subviews

struct DormMiniStat: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E8E93"))
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
