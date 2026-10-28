//
//  GradeAnalysisContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import Charts
import SwiftUI

#if os(iOS)
import Photos
#endif

struct GradeAnalysisContent: View {
    let analysisData: GradeAnalysisData?

    let canShare: Bool

    let isLoading: Bool

    @Binding var errorToast: ToastState
    @Binding var successToast: ToastState

    let onRefresh: () async -> Void

    enum ChartType: String, CaseIterable {
        case averageGrade = "平均成绩"
        case gpa = "GPA"
    }

    enum DistributionChartType: String, CaseIterable {
        case gradePoint = "绩点"
        case gradeRange = "成绩"
    }

    // 绩点到成绩段的映射
    static let gradePointToRangeMap: [Double: String] = {
        var map: [Double: String] = [:]
        for range in ColorUtil.gradeRanges {
            map[range.point] = range.range
        }
        return map
    }()

    @State private var selectedChartType: ChartType = .averageGrade
    @State private var selectedDistributionChartType: DistributionChartType = .gradePoint

    #if os(iOS)
    @Environment(\.colorScheme) private var colorScheme
    @State private var shareContent: Any?
    @State private var isShowingShareSheet: Bool = false
    #endif

    // MARK: - Body

    var body: some View {
        Group {
            if let data = analysisData {
                CustomScrollView {
                    analysisContent(data)
                }
            } else {
                ContentUnavailableView("暂无成绩数据", systemImage: "doc.text.magnifyingglass", description: Text("当前没有找到成绩数据"))
            }
        }
        .safeRefreshable { await onRefresh() }
        .errorToast($errorToast)
        .successToast($successToast)
        #if os(iOS)
        .sheet(isPresented: $isShowingShareSheet) { ShareSheet(items: [shareContent ?? "分享错误"]) }
        #endif
        .navigationTitle("成绩分析")
        .largeToolbarTitle()
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .secondaryAction) {
                Button(action: showShareSheet) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
                .disabled(isLoading || !canShare)
                Button(action: saveToPhotoAlbum) {
                    Label("保存结果到相册", systemImage: "photo")
                }
                .disabled(isLoading || !canShare)
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefresh) {
                    if isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新成绩分析", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoading)
            }
        }
    }

    // MARK: - Statistic Item

    @ViewBuilder
    private func statisticItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
        }
    }

    // MARK: - Summary Card

    @ViewBuilder
    private func summaryCard(_ gradeAnalysisData: GradeAnalysisData) -> some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("学习总览")
                    .font(.headline)
                    .padding(.bottom, 4)
                HStack {
                    statisticItem(title: "课程总数", value: "\(gradeAnalysisData.totalCourses)", color: .purple)
                    Spacer()
                    statisticItem(title: "总学分", value: String(format: "%.1f", gradeAnalysisData.totalCredits), color: .blue)
                    Spacer()
                    statisticItem(title: "总学时", value: "\(gradeAnalysisData.totalHours)", color: .red)
                }
                Divider()
                HStack {
                    statisticItem(
                        title: "平均成绩",
                        value: String(format: "%.2f", gradeAnalysisData.overallAverageGrade),
                        color: ColorUtil.dynamicColor(grade: gradeAnalysisData.overallAverageGrade)
                    )
                    Spacer()
                    statisticItem(
                        title: "加权平均成绩",
                        value: String(format: "%.2f", gradeAnalysisData.weightedAverageGrade),
                        color: ColorUtil.dynamicColor(grade: gradeAnalysisData.weightedAverageGrade)
                    )
                    Spacer()
                    statisticItem(
                        title: "平均绩点",
                        value: String(format: "%.2f", gradeAnalysisData.overallGPA),
                        color: ColorUtil.dynamicColor(point: gradeAnalysisData.overallGPA)
                    )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Semester Analysis Section

    @ViewBuilder
    private func semesterAnalysisSection(_ gradeAnalysisData: GradeAnalysisData, isShareable: Bool = false) -> some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isShareable ? "学期\(selectedChartType.rawValue)" : "学期平均成绩/GPA")
                        .font(.headline)
                    Spacer()
                    if !isShareable {
                        Picker("图表类型", selection: $selectedChartType.withAnimation()) {
                            ForEach(ChartType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                }
                .padding(.horizontal)

                if selectedChartType == .averageGrade {
                    Chart(gradeAnalysisData.semesterAverageGrades, id: \.semester) { item in
                        LineMark(
                            x: .value("学期", item.semester),
                            y: .value("平均成绩", item.average)
                        )
                        .foregroundStyle(ColorUtil.dynamicColor(grade: item.average))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        PointMark(
                            x: .value("学期", item.semester),
                            y: .value("平均成绩", item.average)
                        )
                        .foregroundStyle(ColorUtil.dynamicColor(grade: item.average))
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", item.average))
                                .font(.system(size: 10))
                                .padding(4)
                                .background(ColorUtil.dynamicColor(grade: item.average).opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .frame(height: 250)
                    .padding()
                } else {
                    Chart(gradeAnalysisData.semesterGPAs, id: \.semester) { item in
                        LineMark(
                            x: .value("学期", item.semester),
                            y: .value("GPA", item.gpa)
                        )
                        .foregroundStyle(ColorUtil.dynamicColor(point: item.gpa))
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        PointMark(
                            x: .value("学期", item.semester),
                            y: .value("GPA", item.gpa)
                        )
                        .foregroundStyle(ColorUtil.dynamicColor(point: item.gpa))
                        .annotation(position: .top) {
                            Text(String(format: "%.2f", item.gpa))
                                .font(.system(size: 10))
                                .padding(4)
                                .background(ColorUtil.dynamicColor(point: item.gpa).opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .frame(height: 250)
                    .padding()
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isShareable ? "\(selectedDistributionChartType.rawValue)分布" : "绩点/成绩分布")
                        .font(.headline)
                    Spacer()
                    if !isShareable {
                        Picker("分布类型", selection: $selectedDistributionChartType.withAnimation()) {
                            ForEach(DistributionChartType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .fixedSize()
                    }
                }
                .padding(.horizontal)

                Chart(gradeAnalysisData.gradePointDistribution, id: \.gradePoint) { item in
                    BarMark(
                        x: .value(
                            selectedDistributionChartType == .gradePoint ? "绩点" : "成绩段",
                            selectedDistributionChartType == .gradePoint
                                ? String(format: "%.1f", item.gradePoint)
                                : (Self.gradePointToRangeMap[item.gradePoint] ?? "")
                        ),
                        y: .value("课程数", item.count)
                    )
                    .foregroundStyle(ColorUtil.dynamicColor(point: item.gradePoint))
                    .annotation(position: .top) {
                        Text("\(item.count)")
                            .font(.system(size: 10).bold())
                            .foregroundColor(ColorUtil.dynamicColor(point: item.gradePoint))
                            .padding(4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks {
                        AxisValueLabel()
                            .font(selectedDistributionChartType == .gradeRange ? .system(size: 9) : .system(size: 11))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .frame(height: 220)
                .padding()
            }
        }
    }

    // MARK: - Analysis Content

    @ViewBuilder
    private func analysisContent(_ gradeAnalysisData: GradeAnalysisData, isShareable: Bool = false) -> some View {
        VStack(spacing: 20) {
            summaryCard(gradeAnalysisData)
            semesterAnalysisSection(gradeAnalysisData, isShareable: isShareable)
        }
    }

    #if os(iOS)
    // MARK: - Shareable View

    @ViewBuilder
    private var shareableView: some View {
        if let data = analysisData {
            analysisContent(data, isShareable: true)
                .padding(.vertical)
                .frame(width: UIScreen.main.bounds.width)
                .background(Color(PlatformColor.systemGroupedBackground))
                .environment(\.colorScheme, colorScheme)
        } else {
            ContentUnavailableView("暂无成绩数据", systemImage: "doc.text.magnifyingglass", description: Text("当前没有找到成绩数据"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func showShareSheet() {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage else {
            errorToast.show(message: "生成图片失败")
            return
        }
        shareContent = ImageActivityItemSource(title: "我的成绩分析", image: uiImage)
        isShowingShareSheet = true
    }

    private func saveToPhotoAlbum() {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage else {
            errorToast.show(message: "生成图片失败")
            return
        }

        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
                }
                successToast.show(message: "图片保存成功")
            } catch {
                errorToast.show(message: "保存图片失败，可能是没有权限: \(error.localizedDescription)")
            }
        }
    }
    #endif
}
