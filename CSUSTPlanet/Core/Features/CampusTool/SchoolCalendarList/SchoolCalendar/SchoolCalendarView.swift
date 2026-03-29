//
//  SchoolCalendarView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SchoolCalendarView: View {
    let schoolCalendar: SchoolCalendar

    @State private var viewModel = SchoolCalendarViewModel()

    // 控制是否显示行内悬浮备注
    @State private var showInlineNotes: Bool = true

    // MARK: - UI 配置常量
    let horizontalPadding: CGFloat = 16
    let sectionSpacing: CGFloat = 16
    let innerSpacing: CGFloat = 8
    let cornerRadius: CGFloat = 12
    let borderThick: CGFloat = 1.5
    let borderThin: CGFloat = 0.5

    let weekColRatio: CGFloat = 0.12
    let monthColRatio: CGFloat = 0.12

    var cardBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.white
        #endif
    }

    var headerBackground: Color {
        #if os(iOS)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #else
        return Color.gray.opacity(0.08)
        #endif
    }

    var separator: Color {
        #if os(iOS)
        return Color(uiColor: .separator)
        #elseif os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color.gray.opacity(0.2)
        #endif
    }

    var weekendText: Color {
        Color.red.opacity(0.7)
    }

    var customWeekBackground: Color {
        Color.accentColor.opacity(0.12)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.config != nil {
                GeometryReader { proxy in
                    let tableWidth = proxy.size.width - (horizontalPadding * 2)
                    let weekColWidth = tableWidth * weekColRatio
                    let monthColWidth = tableWidth * monthColRatio
                    let dayColWidth = (tableWidth - weekColWidth - monthColWidth) / 7

                    ScrollView {
                        VStack(spacing: sectionSpacing) {
                            // 静态概览卡片
                            overviewCard

                            // 表格控制栏
                            HStack {
                                Text("校历详情")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("按住表格隐藏备注")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                            // 表格主体
                            tableBody(weekWidth: weekColWidth, monthWidth: monthColWidth, dayWidth: dayColWidth)
                                .background(cardBackground)
                                // 挂载行内悬浮备注层，与表格顶部对齐
                                .overlay(alignment: .top) {
                                    if showInlineNotes {
                                        inlineNotesOverlay
                                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                                    }
                                }
                                .animation(.easeInOut(duration: 0.2), value: showInlineNotes)
                                .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, perform: {}) { isPressing in
                                    if showInlineNotes == isPressing {
                                        showInlineNotes = !isPressing
                                    }
                                }
                                .padding(.horizontal, horizontalPadding)
                                .padding(.bottom, 20)
                        }
                        .padding(.vertical, sectionSpacing)
                    }
                }
            } else {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                        .smallControlSizeOnMac()
                } else {
                    ContentUnavailableView("无校历数据", systemImage: "calendar.badge.exclamationmark")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("\(schoolCalendar.semesterCode)学年度校历")
        .navigationSubtitleCompat(schoolCalendar.subtitle)
        .task { await viewModel.loadConfig(semester: schoolCalendar.semesterCode) }
        .errorToast($viewModel.errorToast)
        .trackView("SchoolCalendar")
    }

    // MARK: - 学期概览静态卡片
    private var overviewCard: some View {
        CustomGroupBox {
            if let conf = viewModel.config {
                VStack(alignment: .leading, spacing: innerSpacing) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.accentColor)
                        Text("学期概览")
                            .font(.headline)
                        Spacer()
                    }

                    Divider()
                        .background(separator)

                    Text("学期：\(conf.subtitle)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("周期：\(String(conf.semesterStart.prefix(10))) 至 \(String(conf.semesterEnd.prefix(10)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
    }

    // MARK: - 表头
    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(width: width, height: viewModel.headerHeight)
            .background(headerBackground)
            .customBorder(width: borderThin, edges: [.bottom, .trailing], color: separator)
    }

    // MARK: - 表格主体
    private func tableBody(weekWidth: CGFloat, monthWidth: CGFloat, dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // 周次列
            VStack(spacing: 0) {
                headerCell("周", width: weekWidth)
                ForEach(viewModel.weekSpans) { span in
                    Text(span.text)
                        .font(.caption)
                        .fontWeight(span.isCustom ? .bold : .regular)
                        .foregroundColor(span.isCustom ? .accentColor : .secondary)
                        .frame(width: weekWidth, height: viewModel.rowHeight * CGFloat(span.rowCount))
                        .background(span.isCustom ? customWeekBackground : Color.clear)
                        .customBorder(width: borderThin, edges: [.bottom, .trailing], color: separator)
                }
            }

            // 月份列
            VStack(spacing: 0) {
                headerCell("月", width: monthWidth)
                ForEach(viewModel.monthSpans) { span in
                    Text(span.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .frame(width: monthWidth, height: viewModel.rowHeight * CGFloat(span.rowCount))
                        .background(headerBackground.opacity(0.5))
                        .customBorder(width: borderThin, edges: [.bottom, .trailing], color: separator)
                }
            }

            // 七天日期列
            ForEach(0..<7, id: \.self) { dayIndex in
                VStack(spacing: 0) {
                    headerCell(viewModel.dayNames[dayIndex], width: dayWidth)
                    ForEach(0..<viewModel.weeks.count, id: \.self) { rowIndex in
                        dayCell(rowIndex: rowIndex, colIndex: dayIndex, dayWidth: dayWidth)
                    }
                }
            }
        }
    }

    // MARK: - 行内悬浮备注层
    private var inlineNotesOverlay: some View {
        VStack(spacing: 0) {
            // 占位，跳过表头的高度
            Color.clear.frame(height: viewModel.headerHeight)

            // 遍历每一行，如果有备注，就放置气泡
            ForEach(0..<viewModel.notes.count, id: \.self) { index in
                let note = viewModel.notes[index]
                if !note.isEmpty {
                    HStack {
                        Spacer()  // 将气泡推到右侧
                        Text(note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .apply { view in
                                #if os(iOS) || os(macOS)
                                if #available(iOS 26.0, macOS 26.0, *) {
                                    view.glassEffect()
                                } else {
                                    view.background(.ultraThinMaterial, in: Capsule())
                                }
                                #elseif os(visionOS)
                                view
                                #endif
                            }
                            .padding(.trailing, 8)
                            .padding(.leading, 40)
                    }
                    .frame(height: viewModel.rowHeight)
                } else {
                    Color.clear.frame(height: viewModel.rowHeight)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 日期单元格与高亮逻辑
    private func dayCell(rowIndex: Int, colIndex: Int, dayWidth: CGFloat) -> some View {
        let dayData = viewModel.weeks[rowIndex].days[colIndex]
        let currentMonthKey = dayData.monthKey

        var thickEdges: [RectEdge] = []
        // 获取上下左右邻居
        let topKey = rowIndex > 0 ? viewModel.weeks[rowIndex - 1].days[colIndex].monthKey : nil
        let bottomKey = rowIndex < viewModel.weeks.count - 1 ? viewModel.weeks[rowIndex + 1].days[colIndex].monthKey : nil
        let leftKey = colIndex > 0 ? viewModel.weeks[rowIndex].days[colIndex - 1].monthKey : nil
        let rightKey = colIndex < 6 ? viewModel.weeks[rowIndex].days[colIndex + 1].monthKey : nil

        // 获取对角线邻居 (用于判定是否处于内角)
        let topLeftKey = (rowIndex > 0 && colIndex > 0) ? viewModel.weeks[rowIndex - 1].days[colIndex - 1].monthKey : nil
        let topRightKey = (rowIndex > 0 && colIndex < 6) ? viewModel.weeks[rowIndex - 1].days[colIndex + 1].monthKey : nil
        let bottomLeftKey = (rowIndex < viewModel.weeks.count - 1 && colIndex > 0) ? viewModel.weeks[rowIndex + 1].days[colIndex - 1].monthKey : nil
        let bottomRightKey = (rowIndex < viewModel.weeks.count - 1 && colIndex < 6) ? viewModel.weeks[rowIndex + 1].days[colIndex + 1].monthKey : nil

        // 绘制标准外边界
        if topKey != currentMonthKey { thickEdges.append(.top) }
        if bottomKey != currentMonthKey { thickEdges.append(.bottom) }
        if leftKey != currentMonthKey { thickEdges.append(.leading) }
        if rightKey != currentMonthKey { thickEdges.append(.trailing) }

        // 绘制内角修补块
        if topKey == currentMonthKey && leftKey == currentMonthKey && topLeftKey != nil && topLeftKey != currentMonthKey {
            thickEdges.append(.topLeft)
        }
        if topKey == currentMonthKey && rightKey == currentMonthKey && topRightKey != nil && topRightKey != currentMonthKey {
            thickEdges.append(.topRight)
        }
        if bottomKey == currentMonthKey && leftKey == currentMonthKey && bottomLeftKey != nil && bottomLeftKey != currentMonthKey {
            thickEdges.append(.bottomLeft)
        }
        if bottomKey == currentMonthKey && rightKey == currentMonthKey && bottomRightKey != nil && bottomRightKey != currentMonthKey {
            thickEdges.append(.bottomRight)
        }

        let highlightColor = Color.accentColor.opacity(0.8)

        return Text("\(dayData.day)")
            .font(.footnote)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundColor(dayData.isWeekend ? weekendText : .primary)
            .frame(width: dayWidth, height: viewModel.rowHeight)
            .customBorder(width: borderThin, edges: [.bottom, .trailing], color: separator)
            .customBorder(width: borderThick, edges: thickEdges, color: highlightColor)
    }
}

private enum RectEdge {
    case top, bottom, leading, trailing
    case topLeft, topRight, bottomLeft, bottomRight
}

// MARK: - 边框绘制扩展
private struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [RectEdge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            switch edge {
            case .top:
                path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: width))
            case .bottom:
                path.addRect(CGRect(x: 0, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:
                path.addRect(CGRect(x: 0, y: 0, width: width, height: rect.height))
            case .trailing:
                path.addRect(CGRect(x: rect.maxX - width, y: 0, width: width, height: rect.height))
            case .topLeft:
                path.addRect(CGRect(x: 0, y: 0, width: width, height: width))
            case .topRight:
                path.addRect(CGRect(x: rect.maxX - width, y: 0, width: width, height: width))
            case .bottomLeft:
                path.addRect(CGRect(x: 0, y: rect.maxY - width, width: width, height: width))
            case .bottomRight:
                path.addRect(CGRect(x: rect.maxX - width, y: rect.maxY - width, width: width, height: width))
            }
        }
        return path
    }
}

extension View {
    fileprivate func customBorder(width: CGFloat, edges: [RectEdge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
