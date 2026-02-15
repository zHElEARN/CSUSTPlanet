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
        Color(hex: "FFD60A"),  // 第一名
        Color(hex: "C0C0C0"),  // 第二名
        Color(hex: "CD7F32"),  // 第三名
    ]

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景
            GeometryReader { geo in
                Circle()
                    .fill(textSecondary.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.2)
                    .blur(radius: 40)
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部标题 ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("SECTION 03")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("LOCATIONS & TEACHERS")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("教学楼去往频次与授课教师排行")
                        .font(.system(size: 13))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 50)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -10)

                Spacer(minLength: 20)

                // --- 1. 教学楼去往频次 (Top 5) ---
                VStack(alignment: .leading, spacing: 12) {
                    LabelHeader(title: "BUILDINGS / 教学楼去往频次 TOP 5")

                    let sortedBuildings = data.buildingFrequency.sorted { $0.value > $1.value }.prefix(5)

                    VStack(spacing: 8) {
                        ForEach(Array(zip(sortedBuildings.indices, sortedBuildings)), id: \.0) { index, item in
                            HStack {
                                Text("\(index + 1)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(index < 3 ? rankColors[index] : textSecondary)
                                    .frame(width: 20, alignment: .leading)

                                Text(item.key)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(textPrimary)

                                Spacer()

                                Text("\(item.value)")
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundStyle(textPrimary)

                                Text("次")
                                    .font(.system(size: 11))
                                    .foregroundStyle(textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showBuildings ? 1 : 0)
                .offset(x: showBuildings ? 0 : -20)

                Spacer(minLength: 20)

                // --- 2. 每周上课分布 ---
                VStack(alignment: .leading, spacing: 12) {
                    LabelHeader(title: "WEEKLY SCHEDULE / 每周上课次数分布")

                    HStack(alignment: .bottom, spacing: 10) {
                        let weekData = processWeeklyData(data.dailyClassFrequency)
                        let maxCount = weekData.map { $0.value }.max() ?? 1

                        ForEach(weekData, id: \.dayStr) { item in
                            VStack(spacing: 4) {
                                // 柱状图上方的数字
                                Text("\(item.value)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(item.value == maxCount ? accentColor : textSecondary)
                                    .opacity(showWeeklyChart ? 1 : 0)
                                    .frame(height: 12)

                                // 柱状图
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(item.value == maxCount ? accentColor : textSecondary.opacity(0.3))
                                    .frame(height: showWeeklyChart ? 60 * (CGFloat(item.value) / CGFloat(max(maxCount, 1))) : 0)
                                    .frame(maxHeight: 60, alignment: .bottom)

                                // 星期标签
                                Text(item.dayStr)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(item.value == maxCount ? textPrimary : textSecondary)
                                    .frame(height: 12)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal, 24)
                .opacity(showWeeklyChart ? 1 : 0)
                .offset(y: showWeeklyChart ? 0 : 20)

                Spacer(minLength: 20)

                // --- 3. 授课教师排行 (3x2 网格) ---
                VStack(alignment: .leading, spacing: 12) {
                    LabelHeader(title: "TEACHERS / 授课教师频率排行")

                    let sortedTeachers = data.teacherRanking.sorted { $0.value > $1.value }.prefix(6)
                    let columns = [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                    ]

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(zip(sortedTeachers.indices, sortedTeachers)), id: \.0) { index, item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("#\(index + 1)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(textSecondary)

                                Text(item.key)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(textPrimary)
                                    .lineLimit(2)
                                    .frame(height: 28, alignment: .topLeading)

                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text("\(item.value)")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(accentColor)
                                    Text("次")
                                        .font(.system(size: 9))
                                        .foregroundStyle(textSecondary)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "1C1C1E"))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showTeachers ? 1 : 0)
                .offset(y: showTeachers ? 0 : 20)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showWeeklyChart)
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
        withAnimation(.easeOut(duration: 0.4)) { showHeader = true }
        withAnimation(.spring().delay(0.2)) { showBuildings = true }
        withAnimation(.spring().delay(0.4)) { showWeeklyChart = true }
        withAnimation(.spring().delay(0.6)) { showTeachers = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onAnimationEnd()
        }
    }

    struct WeekViewData {
        let index: Int
        let dayStr: String
        let value: Int
    }

    private func processWeeklyData(_ raw: [EduHelper.DayOfWeek: Int]) -> [WeekViewData] {
        let days = [
            (EduHelper.DayOfWeek.monday, "周一"),
            (EduHelper.DayOfWeek.tuesday, "周二"),
            (EduHelper.DayOfWeek.wednesday, "周三"),
            (EduHelper.DayOfWeek.thursday, "周四"),
            (EduHelper.DayOfWeek.friday, "周五"),
            (EduHelper.DayOfWeek.saturday, "周六"),
            (EduHelper.DayOfWeek.sunday, "周日"),
        ]
        return days.enumerated().map { idx, item in
            WeekViewData(index: idx, dayStr: item.1, value: raw[item.0] ?? 0)
        }
    }
}

// MARK: - Subviews

struct LabelHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color(hex: "00E096"))
                .frame(width: 2, height: 10)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: "8E8E93"))
                .tracking(1)
        }
    }
}
