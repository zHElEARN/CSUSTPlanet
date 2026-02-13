//
//  SpacePeoplePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import CSUSTKit
import SwiftUI

struct SpacePeoplePage: View {
    // MARK: - Data Input
    let data: AnnualReviewData

    // MARK: - Animation Controls
    var startAnimation: Bool
    var onAnimationEnd: () -> Void

    // MARK: - Internal States
    @State private var hasAnimated = false
    @State private var showHeader = false
    @State private var showBuildings = false
    @State private var showWeeklyChart = false
    @State private var showTeachers = false

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")
    private let rankColors = [
        Color(hex: "FFD60A"),  // Gold
        Color(hex: "C0C0C0"),  // Silver
        Color(hex: "CD7F32"),  // Bronze
    ]

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (抽象轨迹网格)
            GeometryReader { geo in
                Path { path in
                    // 模拟几个连接点
                    let p1 = CGPoint(x: geo.size.width * 0.2, y: geo.size.height * 0.3)
                    let p2 = CGPoint(x: geo.size.width * 0.8, y: geo.size.height * 0.4)
                    let p3 = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.7)

                    path.move(to: p1)
                    path.addLine(to: p2)
                    path.addLine(to: p3)
                    path.closeSubpath()
                }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [10, 20]))
                .foregroundColor(textSecondary.opacity(0.1))

                // 装饰性圆点
                Circle()
                    .fill(textSecondary.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.15)
                    .blur(radius: 20)
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部索引 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 03")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("SPACE & PEOPLE")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("物理空间轨迹与人际交互")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

                Spacer()

                // --- 1. 空间：常去地点 (Top 3) ---
                VStack(alignment: .leading, spacing: 16) {
                    LabelHeader(title: "HOTSPOTS / 教学区域活跃度 TOP 3")

                    let sortedBuildings = data.buildingFrequency.sorted { $0.value > $1.value }.prefix(3)

                    VStack(spacing: 12) {
                        ForEach(Array(zip(sortedBuildings.indices, sortedBuildings)), id: \.0) { index, item in
                            HStack {
                                Text(String(format: "%02d", index + 1))
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundStyle(index < 3 ? rankColors[index] : textSecondary)

                                Text(item.key)  // 建筑名
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(textPrimary)

                                Spacer()

                                Text("\(item.value)")
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundStyle(textPrimary)

                                Text("次打卡")
                                    .font(.system(size: 12))
                                    .foregroundStyle(textSecondary)
                            }
                            .padding(12)
                            .background(Color(hex: "1C1C1E"))  // 卡片背景
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showBuildings ? 1 : 0)
                .offset(x: showBuildings ? 0 : -20)

                Spacer()

                // --- 2. 时间：周分布 (Histogram) ---
                VStack(alignment: .leading, spacing: 16) {
                    LabelHeader(title: "WEEKLY LOAD / 周期性课程负荷分布")

                    HStack(alignment: .bottom, spacing: 12) {
                        // 假设 EduHelper.DayOfWeek 可以排序，这里手动构建周一到周日
                        let weekData = processWeeklyData(data.dailyClassFrequency)
                        let maxCount = weekData.map { $0.value }.max() ?? 1

                        ForEach(weekData, id: \.dayStr) { item in
                            VStack(spacing: 8) {
                                GeometryReader { geo in
                                    VStack {
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(item.value == maxCount ? accentColor : textSecondary.opacity(0.3))
                                            .frame(height: showWeeklyChart ? geo.size.height * (CGFloat(item.value) / CGFloat(maxCount)) : 0)
                                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(item.index) * 0.05), value: showWeeklyChart)
                                    }
                                }
                                .frame(height: 80)  // 柱状图高度

                                Text(item.dayStr)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(item.value == maxCount ? textPrimary : textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 24)
                .opacity(showWeeklyChart ? 1 : 0)
                .offset(y: showWeeklyChart ? 0 : 20)

                Spacer()

                // --- 3. 人物：常去老师 (Top 3) ---
                VStack(alignment: .leading, spacing: 16) {
                    LabelHeader(title: "INTERACTIONS / 高频授课教师记录")

                    let sortedTeachers = data.teacherRanking.sorted { $0.value > $1.value }.prefix(3)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(zip(sortedTeachers.indices, sortedTeachers)), id: \.0) { index, item in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundStyle(textSecondary)
                                        Spacer()
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(textSecondary)
                                    }

                                    Text(item.key)  // 老师名
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(textPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: 2) {
                                        Text("授课")
                                            .font(.system(size: 10))
                                            .foregroundStyle(textSecondary)
                                        Text("\(item.value)")
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundStyle(textPrimary)
                                        Text("次")
                                            .font(.system(size: 10))
                                            .foregroundStyle(textSecondary)
                                    }
                                }
                                .padding(12)
                                .frame(width: 110, height: 90)
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(textSecondary.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showTeachers ? 1 : 0)
                .offset(x: showTeachers ? 0 : 20)
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
            showBuildings = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
            showWeeklyChart = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
            showTeachers = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onAnimationEnd()
        }
    }

    // MARK: - Data Helpers

    // 简单的数据结构用于视图循环
    struct WeekViewData {
        let index: Int
        let dayStr: String
        let value: Int
    }

    // 处理周数据，确保周一到周日排序
    private func processWeeklyData(_ raw: [EduHelper.DayOfWeek: Int]) -> [WeekViewData] {
        // 假设 EduHelper.DayOfWeek 无法直接遍历，手动映射
        // 这里需要依据你实际的 Enum 定义，我用通用的映射逻辑
        let days = [
            (EduHelper.DayOfWeek.monday, "MON"),
            (EduHelper.DayOfWeek.tuesday, "TUE"),
            (EduHelper.DayOfWeek.wednesday, "WED"),
            (EduHelper.DayOfWeek.thursday, "THU"),
            (EduHelper.DayOfWeek.friday, "FRI"),
            (EduHelper.DayOfWeek.saturday, "SAT"),
            (EduHelper.DayOfWeek.sunday, "SUN"),
        ]

        var result: [WeekViewData] = []
        for (idx, item) in days.enumerated() {
            let count = raw[item.0] ?? 0
            result.append(WeekViewData(index: idx, dayStr: item.1, value: count))
        }
        return result
    }
}

// MARK: - Subviews

/// 统一的小标题组件
struct LabelHeader: View {
    let title: String

    var body: some View {
        HStack {
            Rectangle()
                .fill(Color(hex: "00E096"))
                .frame(width: 2, height: 12)

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "8E8E93"))
                .tracking(1)
        }
    }
}
