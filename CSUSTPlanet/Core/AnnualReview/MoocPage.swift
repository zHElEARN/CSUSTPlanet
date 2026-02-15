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
    private let accentColor = Color(hex: "00E096")
    private let errorRed = Color(hex: "FF453A")

    private var hasValidData: Bool {
        return data.moocAvailable && data.moocTotalOnlineMinutes != nil
    }

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (背景光晕)
            if hasValidData {
                Circle()
                    .fill(accentColor.opacity(0.03))
                    .frame(width: 400, height: 400)
                    .blur(radius: 60)
                    .opacity(showData ? 1 : 0)
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部标题 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 04")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("ONLINE LEARNING")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("网络课程平台学习统计")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

                Spacer()

                // --- 数据状态指示 ---
                HStack(spacing: 8) {
                    Circle()
                        .fill(hasValidData ? accentColor : errorRed)
                        .frame(width: 6, height: 6)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                pulseOpacity = 1.0
                            }
                        }

                    Text(hasValidData ? "网络课程平台数据同步成功" : "无法获取网络课程平台学习记录")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(hasValidData ? accentColor : errorRed)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(showStatus ? 1 : 0)

                // --- 核心数据面板 ---
                if let minutes = data.moocTotalOnlineMinutes, let logins = data.moocLoginCount, hasValidData {
                    VStack(spacing: 0) {
                        // 1. 累计在线时长
                        VStack(alignment: .leading, spacing: 12) {
                            Text("累计在线时长")
                                .font(.system(size: 12))
                                .foregroundStyle(textSecondary)

                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(minutes)")
                                    .font(.system(size: 56, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(textPrimary)

                                Text("分钟")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(accentColor)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Divider()
                            .background(textSecondary.opacity(0.1))
                            .padding(.horizontal, 24)

                        // 2. 登录次数
                        HStack {
                            Text("网络课程平台登录访问次数")
                                .font(.system(size: 14))
                                .foregroundStyle(textSecondary)

                            Spacer()

                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(logins)")
                                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                                    .foregroundStyle(textPrimary)
                                Text("次")
                                    .font(.system(size: 12))
                                    .foregroundStyle(textSecondary)
                            }
                        }
                        .padding(24)
                    }
                    .background(Color(hex: "1C1C1E"))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .opacity(showData ? 1 : 0)
                    .offset(y: showData ? 0 : 20)

                } else {
                    // --- 异常/无数据状态 ---
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundStyle(textSecondary.opacity(0.5))

                        VStack(spacing: 8) {
                            Text("无法同步网络课程平台数据")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(textPrimary)

                            Text("可能原因：学校服务器离线、登录授权过期或当前账号无学习记录。请尝试重新打开报告，或等待学校平台服务恢复后再试。")
                                .font(.system(size: 13))
                                .foregroundStyle(textSecondary)
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "1C1C1E").opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)
                    .opacity(showData ? 1 : 0)
                }

                Spacer()

                // 底部提示信息
                if hasValidData {
                    Text("数据来源：网络课程平台后台记录")
                        .font(.system(size: 10))
                        .foregroundStyle(textSecondary.opacity(0.3))
                        .padding(.bottom, 40)
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

    private func performAnimation() {
        hasAnimated = true
        withAnimation(.easeOut(duration: 0.5)) { showHeader = true }
        withAnimation(.spring().delay(0.2)) { showStatus = true }
        withAnimation(.spring().delay(0.4)) { showData = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onAnimationEnd()
        }
    }
}
