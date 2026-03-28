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
    @Namespace var namespace
    @State private var refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000)

    var body: some View {
        Group {
            #if os(macOS)
            TrackLink(destination: GradeQueryView()) {
                CustomGroupBox {
                    cardContent
                }
                .frame(height: 130)
                .frame(maxWidth: .infinity)
            }
            #elseif os(iOS)
            if #available(iOS 18.0, macOS 15.0, *) {
                TrackLink(
                    destination: GradeQueryView()
                        .navigationTransition(.zoom(sourceID: "gradeQuery", in: namespace))
                        .onDisappear { refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000) }
                ) {
                    CustomGroupBox {
                        cardContent.matchedTransitionSource(id: "gradeQuery", in: namespace)
                    }
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                }
                .id(refreshID)
            } else {
                TrackLink(destination: GradeQueryView()) {
                    CustomGroupBox {
                        cardContent
                    }
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                }
            }
            #endif
        }
        .buttonStyle(.plain)
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("成绩查询")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Spacer(minLength: 0)

                if let gradeAnalysis = viewModel.gradeAnalysis {
                    Text(String(format: "%.2f", gradeAnalysis.overallGPA))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorUtil.dynamicColor(point: gradeAnalysis.overallGPA))

                    Text("平均分: \(String(format: "%.1f", gradeAnalysis.overallAverageGrade))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("-.-")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            gradeTrendChart
                .frame(width: 120)
                .frame(maxHeight: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
