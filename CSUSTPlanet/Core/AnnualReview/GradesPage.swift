//
//  GradesPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import CSUSTKit
import SwiftUI

struct GradesPage: View {
    // MARK: - Data Input
    let data: AnnualReviewData

    // MARK: - Animation Controls
    var startAnimation: Bool
    var onAnimationEnd: () -> Void

    // MARK: - Internal States
    @State private var hasAnimated = false
    @State private var showHeader = false
    @State private var showGPA = false
    @State private var showDetailStats = false
    @State private var showCourseLists = false

    // GPA 环形进度动画
    @State private var gpaProgress: CGFloat = 0.0

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let cardBg = Color(hex: "1C1C1E")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")  // 绿色，代表优秀/通过
    private let warnColor = Color(hex: "FFD60A")  // 黄色，代表警告/刚好及格
    private let dangerColor = Color(hex: "FF453A")  // 红色，代表挂科

    var body: some View {
        ZStack {
            // 1. 背景层
            themeBg.ignoresSafeArea()

            // 2. 装饰性背景 (成绩波动折线)
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    // 绘制一条简单的折线背景
                    path.move(to: CGPoint(x: 0, y: h * 0.6))
                    path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.55))
                    path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.65))
                    path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.4))
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.45))
                    path.addLine(to: CGPoint(x: w, y: h * 0.3))
                }
                .stroke(textSecondary.opacity(0.1), lineWidth: 1)
            }

            // 3. 内容层
            VStack(spacing: 0) {
                // --- 顶部索引 ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("SECTION 05")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("ACADEMIC GRADES")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("年度学业成绩单")
                        .font(.system(size: 14))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : -20)

                Spacer()

                // --- 核心指标：GPA ---
                ZStack {
                    // 轨道
                    Circle()
                        .stroke(textSecondary.opacity(0.2), lineWidth: 15)
                        .frame(width: 220, height: 220)

                    // 进度条 (最大值4.0)
                    Circle()
                        .trim(from: 0, to: gpaProgress)
                        .stroke(
                            LinearGradient(
                                colors: [accentColor.opacity(0.7), accentColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))

                    // 内部文字
                    VStack(spacing: 4) {
                        Text("平均绩点")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(textSecondary)

                        Text(String(format: "%.2f", data.annualGPA))
                            .font(.system(size: 56, weight: .heavy, design: .monospaced))
                            .foregroundStyle(textPrimary)
                            .tracking(-2)

                        Text("GPA / 4.0")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(textSecondary.opacity(0.5))
                    }
                }
                .opacity(showGPA ? 1 : 0)
                .scaleEffect(showGPA ? 1 : 0.9)
                .padding(.vertical, 30)

                // --- 详细数据网格 ---
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    GradeStatBox(label: "已修读总学分", value: String(format: "%.1f", data.totalCredits))
                    GradeStatBox(label: "完成课程总数", value: "\(data.totalCoursesCount)")
                    GradeStatBox(label: "考试课程数量", value: "\(data.examCount)")
                    GradeStatBox(label: "考查课程数量", value: "\(data.assessmentCount)")
                }
                .padding(.horizontal, 24)
                .opacity(showDetailStats ? 1 : 0)
                .offset(y: showDetailStats ? 0 : 20)

                Spacer()

                // --- 特殊课程列表 (如果有) ---
                VStack(spacing: 12) {
                    // 1. 最高分展示
                    if let highest = data.highestGradeCourses.first {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HIGHEST SCORE / 单科最高成绩")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(accentColor)
                                Text(highest.courseName)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(textPrimary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("\(highest.grade)")  // 成绩
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(accentColor)
                        }
                        .padding(16)
                        .background(cardBg)
                        .cornerRadius(12)
                    }

                    // 2. 挂科警示 (仅当有挂科时显示)
                    if !data.failedCourses.isEmpty {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NOT PASSED / 未通过课程")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(dangerColor)
                                Text("\(data.failedCourses.count) 门课程需要重修")
                                    .font(.system(size: 14))
                                    .foregroundStyle(textPrimary)
                            }
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(dangerColor)
                        }
                        .padding(16)
                        .background(dangerColor.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(dangerColor.opacity(0.3), lineWidth: 1)
                        )
                    } else if !data.fullGradePointCourses.isEmpty {
                        // 如果没有挂科，且有满绩，显示满绩数量
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FULL GPA / 满绩点课程")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color(hex: "FFD60A"))  // 金色
                                Text("\(data.fullGradePointCourses.count) 门课程取得 4.0 满绩")
                                    .font(.system(size: 14))
                                    .foregroundStyle(textPrimary)
                            }
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color(hex: "FFD60A"))
                        }
                        .padding(16)
                        .background(Color(hex: "FFD60A").opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showCourseLists ? 1 : 0)
                .offset(y: showCourseLists ? 0 : 20)
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

        // 2. GPA 圆环出现
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showGPA = true
        }

        // 3. GPA 进度条生长动画 (0 -> actual GPA)
        let targetProgress = CGFloat(data.annualGPA / 4.0)
        withAnimation(.easeOut(duration: 1.5).delay(0.4)) {
            gpaProgress = targetProgress
        }

        // 4. 数据网格
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            showDetailStats = true
        }

        // 5. 底部列表
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showCourseLists = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onAnimationEnd()
        }
    }
}

// MARK: - Subviews

struct GradeStatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E8E93"))

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: "FFFFFF"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
    }
}
