//
//  MoocPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct MoocPage: View {
    // MARK: - Data Input
    let data: AnnualReviewData

    // MARK: - Animation Controls
    var startAnimation: Bool
    var onAnimationEnd: () -> Void

    // MARK: - Internal States
    @State private var hasAnimated = false
    @State private var showHeader = false
    @State private var showStatus = false
    @State private var showData = false
    @State private var pulseOpacity = 0.2

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let terminalGreen = Color(hex: "00E096")  // 特有的终端绿
    private let errorRed = Color(hex: "FF453A")

    // Check if data is valid
    private var hasValidData: Bool {
        return data.moocAvailable && data.moocTotalOnlineMinutes != nil
    }

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (数字脉冲)
            ZStack {
                if hasValidData {
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(terminalGreen.opacity(0.1), lineWidth: 1)
                            .frame(width: 200 + CGFloat(i * 100), height: 200 + CGFloat(i * 100))
                            .scaleEffect(showStatus ? 1.2 : 0.8)
                            .opacity(showStatus ? 0 : 0.3)
                            .animation(
                                Animation.easeOut(duration: 3)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.5),
                                value: showStatus
                            )
                    }
                }
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部索引 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 04")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(terminalGreen)
                        .tracking(2)

                    Text("DIGITAL FOOTPRINT")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("网络课程云端日志")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

                Spacer()

                // --- 状态指示器 ---
                HStack(spacing: 12) {
                    Circle()
                        .fill(hasValidData ? terminalGreen : errorRed)
                        .frame(width: 8, height: 8)
                        .shadow(color: (hasValidData ? terminalGreen : errorRed).opacity(0.8), radius: 6)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                pulseOpacity = 1.0
                            }
                        }

                    Text(hasValidData ? "CONNECTION ESTABLISHED" : "NO SIGNAL DETECTED")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(hasValidData ? terminalGreen : errorRed)
                        .tracking(1)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(showStatus ? 1 : 0)

                // --- 核心数据展示 ---
                if let minutes = data.moocTotalOnlineMinutes, let logins = data.moocLoginCount, hasValidData {
                    VStack(spacing: 2) {
                        // 1. 在线时长卡片 (模拟终端窗口)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                    .foregroundStyle(terminalGreen)
                                Text("SESSION_DURATION_TOTAL")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(terminalGreen.opacity(0.8))
                            }

                            HStack(alignment: .lastTextBaseline) {
                                Text("\(minutes)")
                                    .font(.system(size: 60, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(textPrimary)
                                    .tracking(-2)

                                Text("MINS")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(terminalGreen)
                                    .padding(.leading, 4)
                            }

                            Text("云端累计在线时长")
                                .font(.system(size: 14))
                                .foregroundStyle(textSecondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: "1C1C1E"))
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(terminalGreen.opacity(0.3)),
                            alignment: .top
                        )

                        // 2. 登录次数卡片
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "network")
                                        .font(.system(size: 12))
                                        .foregroundStyle(textSecondary)
                                    Text("ACCESS_LOGS")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(textSecondary)
                                }

                                Text("平台访问会话次数")
                                    .font(.system(size: 14))
                                    .foregroundStyle(textSecondary)
                            }

                            Spacer()

                            HStack(alignment: .firstTextBaseline) {
                                Text("\(logins)")
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundStyle(textPrimary)
                                Text("次")
                                    .font(.system(size: 12))
                                    .foregroundStyle(textSecondary)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "1C1C1E").opacity(0.5))
                    }
                    .padding(.horizontal, 24)
                    .opacity(showData ? 1 : 0)
                    .offset(y: showData ? 0 : 20)
                } else {
                    // 无数据状态
                    VStack(spacing: 16) {
                        Image(systemName: "icloud.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(textSecondary.opacity(0.3))

                        Text("当前账号未检测到网络课程学习记录")
                            .font(.system(size: 14))
                            .foregroundStyle(textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .background(Color(hex: "1C1C1E").opacity(0.3))
                    .cornerRadius(12)
                    .padding(24)
                    .opacity(showData ? 1 : 0)
                }

                Spacer()

                // 底部装饰
                Text("// END OF STREAM")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(textSecondary.opacity(0.2))
                    .padding(.bottom, 40)
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

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            showStatus = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            showData = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onAnimationEnd()
        }
    }
}
