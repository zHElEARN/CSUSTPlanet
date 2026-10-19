//
//  GradeDetailDistributionSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeDetailDistributionSection: View {
    let detail: EduHelper.GradeDetail?

    private let ringDiameter: CGFloat = 140

    var body: some View {
        if let detail {
            // 权重 ≤ 0 的组成项不参与绘制，环与下方列表基于同一份数据，颜色才不会错位
            let components = detail.components.filter { $0.ratio > 0 }

            VStack(alignment: .leading, spacing: 8) {
                Text("成绩分布")
                    .font(.headline)
                    .padding(.horizontal)

                CustomGroupBox {
                    VStack(spacing: 0) {
                        HStack(alignment: .center, spacing: 16) {
                            ScoreRing(segments: segments(of: components))
                                .frame(width: ringDiameter, height: ringDiameter)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("总成绩：")
                                    .font(.subheadline)

                                Text("\(detail.totalGrade)/100")
                                    .font(.system(.title, design: .rounded))
                                    .bold()
                                    .monospacedDigit()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 12)

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                                componentRow(component, color: ScoreRing.color(at: index))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                    }
                }
            }
        }
    }

    private func segments(of components: [EduHelper.GradeComponent]) -> [ScoreSegment] {
        components.map { ScoreSegment(weight: Double($0.ratio), progress: $0.grade / 100) }
    }

    private func componentRow(_ component: EduHelper.GradeComponent, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text("\(component.type) (\(component.ratio)%)")
                .font(.callout)

            Spacer(minLength: 8)

            Text("\(String(format: "%.1f", component.grade))/100")
                .font(.system(.callout, design: .rounded))
                .monospacedDigit()
        }
    }
}

#Preview("GradeDetailDistributionSection") {
    GradeDetailDistributionSection(detail: GradeQueryPreviewData.detail)
        .padding()
}

#Preview("GradeDetailDistributionSection 五段") {
    GradeDetailDistributionSection(
        detail: EduHelper.GradeDetail(
            components: [
                EduHelper.GradeComponent(type: "考勤", grade: 80, ratio: 5),
                EduHelper.GradeComponent(type: "平时作业", grade: 70, ratio: 15),
                EduHelper.GradeComponent(type: "实验成绩", grade: 60, ratio: 20),
                EduHelper.GradeComponent(type: "课程设计成绩", grade: 90, ratio: 20),
                EduHelper.GradeComponent(type: "期末成绩", grade: 85, ratio: 40),
            ],
            totalGrade: 78
        )
    )
    .padding()
}
