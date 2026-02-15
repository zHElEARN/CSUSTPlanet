//
//  ProfilePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct ProfilePage: View {
    // MARK: - Data Input
    let data: AnnualReviewData

    // MARK: - Animation Controls
    var startAnimation: Bool
    var onAnimationEnd: () -> Void

    // MARK: - Internal States
    @State private var hasAnimated = false
    @State private var showHeader = false
    @State private var showIdentity = false
    @State private var showAffiliation = false
    @State private var showTimeline = false

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let cardBg = Color(hex: "1C1C1E")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")

    // 假设本科为4年制，用于计算进度条
    private let totalCollegeDays: Double = 365 * 4

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景水印 (Logo)
            GeometryReader { geo in
                Image(systemName: "globe")  // 占位符，后续替换为校徽 PNG
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.8)
                    .foregroundStyle(Color.white)
                    .opacity(0.02)  // 极低透明度，仅作为纹理
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.2)
                    .rotationEffect(.degrees(-15))
            }

            // 3. 主要内容区 (垂直分布)
            VStack(alignment: .leading, spacing: 0) {

                // --- 顶部：页面索引 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 01")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("IDENTITY PROFILE")
                        .font(.system(size: 24, weight: .bold))  // 中英混排标题
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("基本信息档案")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(x: showHeader ? 0 : -20)

                Spacer()

                // --- 中部：核心身份信息 ---
                VStack(alignment: .leading, spacing: 30) {

                    // 姓名与学号块
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .lastTextBaseline) {
                            Text(data.name)
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(textPrimary)

                            Text(data.namePinyin.uppercased())
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(textSecondary)
                                .padding(.leading, 4)
                        }

                        // 装饰线
                        Rectangle()
                            .fill(textSecondary.opacity(0.3))
                            .frame(height: 1)

                        HStack {
                            Text("ID")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(accentColor)

                            Text(data.studentID)
                                .font(.system(size: 20, weight: .regular, design: .monospaced))
                                .foregroundStyle(textPrimary)
                                .tracking(2)
                        }
                    }
                    .opacity(showIdentity ? 1 : 0)
                    .offset(y: showIdentity ? 0 : 20)

                    // 院系专业块 (网格化排版)
                    VStack(alignment: .leading, spacing: 20) {
                        InfoGridRow(title: "DEPARTMENT / 院系", value: data.department)
                        InfoGridRow(title: "MAJOR / 专业", value: data.major)
                        InfoGridRow(title: "CLASS / 班级", value: data.className)
                    }
                    .opacity(showAffiliation ? 1 : 0)
                    .offset(y: showAffiliation ? 0 : 20)
                }
                .padding(.horizontal, 24)

                Spacer()

                // --- 底部：时间进度条 ---
                VStack(alignment: .leading, spacing: 16) {
                    // 计算天数
                    let days = daysSinceEnrollment(date: data.enrollmentDate)
                    let dateStr = formatDate(date: data.enrollmentDate)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TIMELINE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(textSecondary)
                            Text("入学时长统计")
                                .font(.system(size: 12))
                                .foregroundStyle(textSecondary)
                        }

                        Spacer()

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(days)")
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundStyle(accentColor)
                            Text("DAYS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(accentColor)
                        }
                    }

                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // 轨道
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)

                            // 进度
                            Rectangle()
                                .fill(accentColor)
                                .frame(width: showTimeline ? geo.size.width * calculateProgress(days: days) : 0, height: 4)
                        }
                    }
                    .frame(height: 4)

                    HStack {
                        Text(dateStr)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(textSecondary)
                        Spacer()
                        Text("GRADUATION")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(textSecondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(showTimeline ? 1 : 0)
                .offset(y: showTimeline ? 0 : 20)
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

        // 1. 头部标题入场
        withAnimation(.easeOut(duration: 0.5)) {
            showHeader = true
        }

        // 2. 身份信息入场
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
            showIdentity = true
        }

        // 3. 院系详情入场
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
            showAffiliation = true
        }

        // 4. 底部时间轴入场 (进度条伸长)
        withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
            showTimeline = true
        }

        // 5. 动画结束回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            onAnimationEnd()
        }
    }

    // MARK: - Logic Helpers

    /// 计算入学至今的天数
    private func daysSinceEnrollment(date: Date?) -> Int {
        guard let date = date else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: Date())
        return components.day ?? 0
    }

    /// 格式化入学日期 (YYYY.MM)
    private func formatDate(date: Date?) -> String {
        guard let date = date else { return "UNKNOWN" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM"
        return formatter.string(from: date)
    }

    /// 计算进度条比例 (0.0 - 1.0)
    private func calculateProgress(days: Int) -> Double {
        let progress = Double(days) / totalCollegeDays
        return min(max(progress, 0.0), 1.0)
    }
}

// MARK: - Subviews

/// 统一风格的网格行组件
struct InfoGridRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "8E8E93"))
                .tracking(1)

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "FFFFFF"))

            // 细分割线
            Rectangle()
                .fill(Color(hex: "FFFFFF").opacity(0.1))
                .frame(height: 1)
        }
    }
}
