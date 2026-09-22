//
//  GradeOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import Charts
import SwiftUI

struct GradeOverviewView: View {
    @State private var viewModel = GradeOverviewViewModel()
    @State private var isGradeHidden = MMKVHelper.OverviewSettings.isGradeHidden
    @Environment(Router.self) private var router

    private let chartHeight: CGFloat = 80

    var body: some View {
        Button(action: { router.deepLinkTo(feature: .gradeQuery) }) {
            CustomGroupBox {
                cardContent
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onReceive(MMKVHelper.OverviewSettings.$isGradeHidden) { newValue in
            isGradeHidden = newValue
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("成绩查询")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Spacer()

                if let lastUpdated = viewModel.cachedAt {
                    LastUpdatedDateView(
                        lastUpdated: lastUpdated,
                        font: .footnote,
                        foregroundStyle: .secondary
                    )
                    .contentTransition(.numericText())
                }

                Button(asyncAction: viewModel.loadGrades) {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .disabled(viewModel.isLoadingGrades)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Spacer()

                    if isGradeHidden {
                        Text("-.-")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text("成绩已隐藏")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let gradeAnalysis = viewModel.gradeAnalysis {
                        Text(String(format: "%.2f", gradeAnalysis.overallGPA))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(ColorUtil.dynamicColor(point: gradeAnalysis.overallGPA))
                            .contentTransition(.numericText())

                        Text("平均分: \(String(format: "%.1f", gradeAnalysis.overallAverageGrade))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    } else {
                        Text("-.-")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("暂无数据")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                if isGradeHidden {
                    Color.clear
                        .frame(minWidth: 120, maxWidth: .infinity, minHeight: chartHeight, maxHeight: chartHeight, alignment: .trailing)
                } else {
                    gradeTrendChart
                        .frame(minWidth: 120, maxWidth: .infinity, maxHeight: chartHeight, alignment: .trailing)
                }
            }
            .redacted(reason: viewModel.isLoadingGrades && !isGradeHidden ? .placeholder : [])
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var gradeTrendChart: some View {
        if let gradeAnalysis = viewModel.gradeAnalysis, !gradeAnalysis.semesterGPAs.isEmpty {
            Chart(gradeAnalysis.semesterGPAs, id: \.semester) { item in
                AreaMark(
                    x: .value("学期", item.semester),
                    yStart: .value("基线", 0),
                    yEnd: .value("GPA", item.gpa)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            ColorUtil.dynamicColor(point: item.gpa).opacity(0.22),
                            ColorUtil.dynamicColor(point: item.gpa).opacity(0.04),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("学期", item.semester),
                    y: .value("GPA", item.gpa)
                )
                .foregroundStyle(ColorUtil.dynamicColor(point: item.gpa).opacity(0.95))
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                if gradeAnalysis.semesterGPAs.count <= 8 {
                    PointMark(
                        x: .value("学期", item.semester),
                        y: .value("GPA", item.gpa)
                    )
                    .foregroundStyle(ColorUtil.dynamicColor(point: item.gpa))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartYScale(domain: .automatic(includesZero: true))
            .chartPlotStyle { plotArea in
                plotArea.background(.clear)
            }
            .allowsHitTesting(false)
            .padding(.vertical, 4)
        } else {
            Color.clear
        }
    }
}
