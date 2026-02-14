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
    @State private var showMainStats = false
    @State private var showAssessmentBar = false
    @State private var showCourseLists = false
    @State private var gpaProgress: CGFloat = 0.0

    // MARK: - Constants
    private let themeBg = Color(hex: "0D0D0D")
    private let cardBg = Color(hex: "1C1C1E")
    private let textPrimary = Color(hex: "FFFFFF")
    private let textSecondary = Color(hex: "8E8E93")
    private let accentColor = Color(hex: "00E096")
    private let warnColor = Color(hex: "FFD60A")
    private let dangerColor = Color(hex: "FF453A")

    var body: some View {
        ZStack {
            themeBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // --- 顶部标题 ---
                VStack(alignment: .leading, spacing: 4) {
                    Text("SECTION 05")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .tracking(2)

                    Text("ACADEMIC GRADES")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .tracking(1)

                    Text("全学年课程成绩统计")
                        .font(.system(size: 13))
                        .foregroundStyle(textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 50)
                .opacity(showHeader ? 1 : 0)

                Spacer(minLength: 20)

                // --- 1. GPA 与基础学分 ---
                HStack(spacing: 30) {
                    ZStack {
                        Circle()
                            .stroke(textSecondary.opacity(0.1), lineWidth: 12)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: gpaProgress)
                            .stroke(accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text(String(format: "%.2f", data.annualGPA))
                                .font(.system(size: 38, weight: .heavy, design: .monospaced))
                                .foregroundStyle(textPrimary)
                            Text("平均绩点")
                                .font(.system(size: 11))
                                .foregroundStyle(textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        StatItem(label: "已修总学分", value: String(format: "%.1f", data.totalCredits))
                        StatItem(label: "完成课程总数", value: "\(data.totalCoursesCount)")
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showMainStats ? 1 : 0)

                Spacer(minLength: 40)

                // --- 2. 考核构成比例条 ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("考核方式分布")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(textSecondary)
                        Spacer()
                        Text("考试 \(data.examCount) / 考查 \(data.assessmentCount)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(textSecondary)
                    }

                    // 比例进度条
                    GeometryReader { geo in
                        HStack(spacing: 4) {
                            let total = CGFloat(max(data.examCount + data.assessmentCount, 1))
                            let examWidth = geo.size.width * (CGFloat(data.examCount) / total)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .frame(width: showAssessmentBar ? max(examWidth - 2, 0) : 0)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(textSecondary.opacity(0.3))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 12)

                    HStack(spacing: 16) {
                        LabelTag(text: "考试课程", color: accentColor)
                        LabelTag(text: "考查课程", color: textSecondary.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .opacity(showAssessmentBar ? 1 : 0)
                .offset(y: showAssessmentBar ? 0 : 20)

                Spacer(minLength: 40)

                // --- 3. 重点课程详情卡片 (更大、两行显示) ---
                VStack(spacing: 14) {
                    // 最高分课程
                    if !data.highestGradeCourses.isEmpty {
                        let names = data.highestGradeCourses.map { $0.courseName }.joined(separator: "、")
                        let score = "\(data.highestGradeCourses.first?.grade ?? 0)分"
                        BigCourseCard(label: "最高成绩", names: names, value: score, color: accentColor)
                    }

                    // 刚好及格
                    if !data.justPassedCourses.isEmpty {
                        let names = data.justPassedCourses.map { $0.courseName }.joined(separator: "、")
                        BigCourseCard(label: "刚好及格", names: names, value: "\(data.justPassedCourses.count)门", color: warnColor)
                    }

                    // 不及格 / 或者显示满绩
                    if !data.failedCourses.isEmpty {
                        let names = data.failedCourses.map { $0.courseName }.joined(separator: "、")
                        BigCourseCard(label: "未通过", names: names, value: "\(data.failedCourses.count)门", color: dangerColor)
                    } else if !data.fullGradePointCourses.isEmpty {
                        let names = data.fullGradePointCourses.map { $0.courseName }.joined(separator: "、")
                        BigCourseCard(label: "满绩点课程", names: names, value: "\(data.fullGradePointCourses.count)门", color: Color(hex: "FFD60A"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showCourseLists ? 1 : 0)
                .offset(y: showCourseLists ? 0 : 20)
            }
        }
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
        withAnimation(.spring().delay(0.2)) { showMainStats = true }
        withAnimation(.easeOut(duration: 1.2).delay(0.4)) {
            gpaProgress = CGFloat(data.annualGPA / 4.0)
        }
        withAnimation(.spring().delay(0.6)) { showAssessmentBar = true }
        withAnimation(.spring().delay(0.8)) { showCourseLists = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onAnimationEnd()
        }
    }
}

// MARK: - Helper Views

struct StatItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E8E93"))
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white)
        }
    }
}

struct LabelTag: View {
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "8E8E93"))
        }
    }
}

struct BigCourseCard: View {
    let label: String
    let names: String
    let value: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.1))
                    .cornerRadius(4)

                Text(names)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.white)
                    .lineLimit(2)  // 允许显示两行
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(20)  // 增加内边距使卡片更大
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}
