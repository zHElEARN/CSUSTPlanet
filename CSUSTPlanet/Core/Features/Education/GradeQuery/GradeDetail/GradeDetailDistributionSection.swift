//
//  GradeDetailDistributionSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import Charts
import SwiftUI

struct GradeDetailDistributionSection: View {
    let detail: EduHelper.GradeDetail?
    @Binding var renderMode: GradeDetailRenderMode

    var body: some View {
        if let detail {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Text("成绩分布")
                        .font(.headline)
                    Spacer()
                    Picker("显示方式", selection: $renderMode.withAnimation()) {
                        ForEach(GradeDetailRenderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                .padding(.horizontal)

                CustomGroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        if renderMode == .pie {
                            pieChart(detail)
                        } else {
                            progressList(detail)
                        }
                    }
                }
            }
        }
    }

    ///成绩详情界面饼图
    private func pieChart(_ detail: EduHelper.GradeDetail) -> some View {
        // 总成绩:EduHelper.GradeDetail.totalGrade: Int

        HStack {
            gradeDetailList(detail)
                .fixedSize(horizontal: true, vertical: false)

            ZStack {
                ///底层权重占比
                Chart(detail.components, id: \.type) { component in
                    SectorMark(
                        angle: .value("占比", component.ratio),
                        innerRadius: .ratio(0.4),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("类型", component.type))
                    .opacity(0.2)
                    .cornerRadius(8.0)
                }
                .chartLegend(.hidden)
                .chartForegroundStyleScale(
                    domain: GradeComponentPalette.typeDomain(for: detail),
                    range: GradeComponentPalette.typeRange(for: detail)
                )

                ///上层实际得分占比
                Chart(detail.components, id: \.type) { component in
                    let scoreProgress = max(0, min(component.grade, 100)) / 100.0
                    let calculatedOuterRadius = 0.4 + (1.0 - 0.4) * scoreProgress

                    SectorMark(
                        angle: .value("占比", component.ratio),
                        innerRadius: .ratio(0.4),
                        outerRadius: .ratio(calculatedOuterRadius),
                        angularInset: 1
                    )
                    .foregroundStyle(by: .value("类型", component.type))
                    .cornerRadius(8.0)
                }
                .chartLegend(.hidden)
                .chartForegroundStyleScale(
                    domain: GradeComponentPalette.typeDomain(for: detail),
                    range: GradeComponentPalette.typeRange(for: detail)
                )

                ///环内总分
                VStack(spacing: 2) {
                    Text("\(detail.totalGrade)")
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                }
            }
        }
        .frame(height: 140)
    }

    ///饼图左侧具体成绩列表
    private func gradeDetailList(_ detail: EduHelper.GradeDetail) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(detail.components, id: \.type) { component in
                gradeDetail(
                    title: "\(component.type) (\(component.ratio)%)",             //成绩类型(占比）
                    gradeText: "\(String(format: "%.1f", component.grade))/100",  //具体成绩/100
                    value: component.grade,
                    isTotal: false,
                    indicatorColor: GradeComponentPalette.color(for: component.type, in: detail)
                )
            }
            
            gradeDetail(
                title: "总成绩 (100%)",
                gradeText: "\(String(format: "%.1f", Double(detail.totalGrade)))/100",
                value: Double(detail.totalGrade),
                isTotal: true,
                indicatorColor: nil,
            )
        }
    }

    ///饼图左侧具体成绩
    private func gradeDetail(
        title: String,
        gradeText: String,
        value: Double,
        isTotal: Bool,
        indicatorColor: Color?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if (!isTotal) {
                    Circle()
                        .fill(indicatorColor!)
                        .frame(width: 9)
                }
                Text(title)
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                Spacer()
                Text(gradeText)
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func progressList(_ detail: EduHelper.GradeDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(detail.components, id: \.type) { component in
                progressRow(
                    title: "\(component.type) (\(component.ratio)%)",
                    gradeText: "\(String(format: "%.1f", component.grade))/100",
                    value: component.grade
                )
            }

            progressRow(
                title: "总成绩 (100%)",
                gradeText: "\(String(format: "%.1f", Double(detail.totalGrade)))/100",
                value: Double(detail.totalGrade)
            )
        }
    }

    private func progressRow(title: String, gradeText: String, value: Double) -> some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.callout)
                    Spacer()
                    Text(gradeText)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: min(max(value, 0), 100), total: 100)
                    .tint(ColorUtil.dynamicColor(grade: value))
            }
        }
}

///成绩分布手动管理配色
private enum GradeComponentPalette {
    ///分类色板
    private static let palette: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .pink,
        .red,
        .yellow,
        .cyan,
        .mint,
        .indigo,
        .teal,
        .brown,
    ]
    
    ///环分类色的 domain
    static func typeDomain(for detail: EduHelper.GradeDetail) -> [String] {
        var seen = Set<String>()
        return detail.components.map(\.type).filter { seen.insert($0).inserted }
    }
    
    ///环分类色的 range
    static func typeRange(for detail: EduHelper.GradeDetail) -> [Color] {
        typeDomain(for: detail).indices.map { palette[$0 % palette.count] }
    }
    
    ///进度条取色
    static func color(for type: String, in detail: EduHelper.GradeDetail) -> Color {
        guard let index = typeDomain(for: detail).firstIndex(of: type) else { return palette[0] }
        return palette[index % palette.count]
    }
}

#Preview("GradeDetailDistributionSection Progress") {
    @Previewable @State var renderMode = GradeDetailRenderMode.progress

    GradeDetailDistributionSection(
        detail: GradeQueryPreviewData.detail,
        renderMode: $renderMode
    )
    .padding()
}

#Preview("GradeDetailDistributionSection Pie") {
    @Previewable @State var renderMode = GradeDetailRenderMode.pie

    GradeDetailDistributionSection(
        detail: GradeQueryPreviewData.detail,
        renderMode: $renderMode
    )
    .padding()
}
