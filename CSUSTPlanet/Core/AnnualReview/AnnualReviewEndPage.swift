//
//  AnnualReviewEndPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI
import Toasts

struct AnnualReviewEndPage: View {
    // MARK: - Environment
    @Environment(\.presentToast) var presentToast

    // MARK: - State Properties
    @State private var hasAnimated = false
    @State private var showContent = false
    @State private var showCursor = false
    @State private var showFeedbackSection = false  // 新增：反馈区域显示控制
    @State private var showFooter = false

    @State private var rating: Int = 0  // 用户评分
    @State private var ratingCount: Int = 0  // 评分次数
    @State private var showSheet = false  // 反馈 Sheet 弹出控制

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
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("2026")
                            .font(.system(size: 80, weight: .heavy))
                            .foregroundStyle(textPrimary)
                            .tracking(-2)

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

                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(textSecondary)
                            .frame(width: 30, height: 1)

                        Text("SEE YOU NEXT YEAR / 明年见")
                            .font(.system(size: 12, weight: .bold))
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

                // --- 反馈与互动区 (新添加) ---
                VStack(spacing: 28) {
                    // 说明文字
                    VStack(spacing: 8) {
                        Text("这是我们第一次尝试制作「年度总结」页面")
                        Text("若有体验不佳或功能欠缺，还请多多包涵")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(textSecondary)
                    .multilineTextAlignment(.center)

                    // 五星评分
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .font(.system(size: 24))
                                    .foregroundStyle(index <= rating ? accentColor : textSecondary.opacity(0.4))
                                    .onTapGesture {
                                        guard ratingCount < 3 else {
                                            presentToast(
                                                ToastValue(
                                                    icon: Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange),
                                                    message: "已达到评分次数上限（最多3次）"
                                                )
                                            )
                                            return
                                        }

                                        withAnimation(.spring()) {
                                            rating = index
                                        }
                                        handleRating(index)
                                    }
                            }
                        }

                        if rating > 0 {
                            Text("感谢你的评分！")
                                .font(.system(size: 12))
                                .foregroundStyle(accentColor)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    // 反馈按钮及提示
                    VStack(spacing: 12) {
                        Button {
                            showSheet = true
                        } label: {
                            HStack {
                                Text("提供反馈建议")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(themeBg)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(accentColor)
                            .clipShape(Capsule())
                        }

                        Text("你的建议将被采纳到 2026 年的总结设计中")
                            .font(.system(size: 11))
                            .foregroundStyle(textSecondary.opacity(0.6))
                    }
                }
                .padding(.bottom, 40)
                .opacity(showFeedbackSection ? 1 : 0)
                .offset(y: showFeedbackSection ? 0 : 30)

                // --- 底部 Logo ---
                VStack(spacing: 12) {
                    Image("MinimalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(textPrimary.opacity(0.8))

                    Text("CSUST PLANET")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(textPrimary)
                        .tracking(2)

                    Text("长理星球")
                        .font(.system(size: 10))
                        .foregroundStyle(textSecondary)
                }
                .padding(.bottom, 50)
                .opacity(showFooter ? 1 : 0)
            }
        }
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                WebView(url: URL(string: "https://my.feishu.cn/share/base/form/shrcnPV8baxInD6OyUm5ZkteX0b")!)
                    .navigationTitle("填写意见调研问卷")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("关闭") {
                                showSheet = false
                            }
                        }
                    }
            }
            .trackView("AnnualReviewFeedback")
        }
        .onAppear {
            performAnimation()
        }
    }

    // MARK: - Logic & Animations
    private func performAnimation() {
        guard !hasAnimated else { return }
        hasAnimated = true

        // 1. 2026 入场
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            showContent = true
        }

        // 2. 反馈区随后入场
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6)) {
            showFeedbackSection = true
        }

        // 3. 底部 Logo 最后出现
        withAnimation(.easeOut(duration: 0.8).delay(1.2)) {
            showFooter = true
        }

        // 启动光标闪烁
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCursor = true
        }
    }

    private func handleRating(_ value: Int) {
        // 增加评分次数
        ratingCount += 1

        // 追踪评分事件
        TrackHelper.shared.event(
            category: "AnnualReview",
            action: "Rating",
            name: "Stars",
            value: NSNumber(value: value)
        )
        TrackHelper.shared.flush()

        // 显示 toast 提示
        let message = ratingCount == 3 ? "感谢你的 \(value) 星评分！（已达评分次数上限）" : "感谢你的 \(value) 星评分！"
        presentToast(
            ToastValue(
                icon: Image(systemName: "star.fill").foregroundStyle(accentColor),
                message: message
            )
        )
    }
}
