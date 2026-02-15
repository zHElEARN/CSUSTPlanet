//
//  AnnualReviewView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import SwiftUI

struct AnnualReviewView: View {
    @StateObject private var viewModel = AnnualReviewViewModel()
    @Binding var isPresented: Bool

    @State private var currentScrollID: Int? = 0
    @State private var isScrollLocked: Bool = false
    @State private var animatedPages: Set<Int> = []

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let accentColor = Color(hex: "00E096")
    private let textSecondary = Color(hex: "8E8E93")
    private let totalPages = 8

    var body: some View {
        ZStack(alignment: .trailing) {
            // 固定深色背景，不受系统主题影响
            themeBg.ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    ProgressView("正在生成年度报告...")
                        .tint(accentColor)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let data = viewModel.reviewData {
                    ScrollView {
                        VStack(spacing: 0) {
                            AnnualReviewStartPage(
                                startAnimation: currentScrollID == 0,
                                onAnimationEnd: { unlockScroll(for: 0) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(0)

                            ProfilePage(
                                data: data,
                                startAnimation: currentScrollID == 1,
                                onAnimationEnd: { unlockScroll(for: 1) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(1)

                            TimeSchedulePage(
                                data: data,
                                startAnimation: currentScrollID == 2,
                                onAnimationEnd: { unlockScroll(for: 2) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(2)

                            SpacePeoplePage(
                                data: data,
                                startAnimation: currentScrollID == 3,
                                onAnimationEnd: { unlockScroll(for: 3) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(3)

                            MoocPage(
                                data: data,
                                startAnimation: currentScrollID == 4,
                                onAnimationEnd: { unlockScroll(for: 4) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(4)

                            GradesPage(
                                data: data,
                                startAnimation: currentScrollID == 5,
                                onAnimationEnd: { unlockScroll(for: 5) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(5)

                            DormPage(
                                data: data,
                                startAnimation: currentScrollID == 6,
                                onAnimationEnd: { unlockScroll(for: 6) }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(6)

                            AnnualReviewEndPage()
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(7)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $currentScrollID)
                    .ignoresSafeArea()  // 保持原始安全区设计
                    .scrollDisabled(isScrollLocked)
                    .onChange(of: currentScrollID) { _, newID in
                        if let id = newID {
                            handlePageChange(pageID: id)
                        }
                    }

                    // --- 优化后的右侧紧凑导航栏 ---
                    VStack(spacing: 12) {
                        // 1. 数字索引
                        VStack(spacing: 2) {
                            Text(String(format: "%02d", (currentScrollID ?? 0) + 1))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(accentColor)

                            Rectangle()
                                .fill(textSecondary.opacity(0.3))
                                .frame(width: 12, height: 1)

                            Text(String(format: "%02d", totalPages))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(textSecondary.opacity(0.6))
                        }

                        // 2. 纵向微缩进度条
                        ZStack(alignment: .top) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 3, height: 60)

                            Capsule()
                                .fill(accentColor)
                                .frame(width: 3, height: 60 * CGFloat((currentScrollID ?? 0) + 1) / CGFloat(totalPages))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentScrollID)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 2)
                    .background {
                        // 独立的背景块，确保不会与页面内容混淆
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.4))
                            .background(BlurView(style: .systemUltraThinMaterialDark))  // 磨砂玻璃效果
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.trailing, 4)
                } else {
                    ContentUnavailableView("无数据", systemImage: "xmark.bin")
                        .foregroundStyle(.white)
                }
            }

            // --- 悬浮关闭按钮 (顶部对齐) ---
            VStack {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color(hex: "2C2C2E").opacity(0.9))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
                }
                Spacer()  // 强行将按钮推到顶部
            }
            .padding(.trailing, 10)
        }
        .trackView("AnnualReview")
        .onAppear {
            viewModel.compute()
            if currentScrollID == 0 && !animatedPages.contains(0) {
                lockScroll(for: 0)
            }
            if let currentID = currentScrollID {
                handlePageChange(pageID: currentID)
            }
        }
    }

    private func handlePageChange(pageID: Int) {
        // 页面埋点
        let pageName: String
        switch pageID {
        case 0:
            pageName = "AnnualReviewStartPage"
        case 1:
            pageName = "AnnualReviewProfilePage"
        case 2:
            pageName = "AnnualReviewTimeSchedulePage"
        case 3:
            pageName = "AnnualReviewSpacePeoplePage"
        case 4:
            pageName = "AnnualReviewMoocPage"
        case 5:
            pageName = "AnnualReviewGradesPage"
        case 6:
            pageName = "AnnualReviewDormPage"
        case 7:
            pageName = "AnnualReviewEndPage"
        default:
            pageName = "AnnualReviewUnknownPage"
        }
        TrackHelper.shared.views(path: ["App", "Features", "AnnualReview", pageName])

        if !animatedPages.contains(pageID) {
            if (0...6).contains(pageID) {
                lockScroll(for: pageID)
            }
        }
    }

    private func lockScroll(for pageID: Int) {
        isScrollLocked = true
    }

    private func unlockScroll(for pageID: Int) {
        withAnimation {
            isScrollLocked = false
        }
        animatedPages.insert(pageID)
    }
}

// 简单的磨砂玻璃辅助视图
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
