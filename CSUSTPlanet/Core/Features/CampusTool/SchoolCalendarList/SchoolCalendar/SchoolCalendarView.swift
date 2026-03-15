//
//  SchoolCalendarView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import SwiftUI

struct SchoolCalendarView: View {
    let schoolCalendar: SchoolCalendar

    @State private var viewModel = SchoolCalendarViewModel()
    @Environment(\.colorScheme) var colorScheme

    // 控制是否显示行内悬浮备注
    @State private var showInlineNotes: Bool = true

    // 动态计算列宽 (总宽度 = 屏幕宽度 - 卡片左右边距 32)
    private var tableWidth: CGFloat { UIScreen.main.bounds.width - 32 }
    private var weekColWidth: CGFloat { tableWidth * 0.12 }
    private var monthColWidth: CGFloat { tableWidth * 0.12 }
    private var dayColWidth: CGFloat { (tableWidth - weekColWidth - monthColWidth) / 7 }

    private var separatorColor: Color { Color(UIColor.separator).opacity(0.5) }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.isShowingError {
                ContentUnavailableView("加载失败", systemImage: "exclamationmark.triangle", description: Text(viewModel.errorMessage))
            } else if viewModel.config != nil {
                ScrollView {
                    VStack(spacing: 16) {
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
                        tableBody
                            .background(Color(UIColor.secondarySystemGroupedBackground))
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
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                    }
                    .padding(.vertical)
                }
            } else {
                Color.clear
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("\(schoolCalendar.semesterCode)学年度校历")
        .apply { view in
            if #available(iOS 26.0, *) {
                view.navigationSubtitle(schoolCalendar.subtitle)
            } else {
                view
            }
        }
        .task {
            if viewModel.config == nil && !viewModel.isLoading && !viewModel.isShowingError {
                await viewModel.loadConfig(semester: schoolCalendar.semesterCode)
            }
        }
    }

    // MARK: - 学期概览静态卡片
    private var overviewCard: some View {
        Group {
            if let conf = viewModel.config {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.accentColor)
                        Text("学期概览")
                            .font(.headline)
                        Spacer()
                    }
                    Divider()
                    Text("学期：\(conf.subtitle.replacingOccurrences(of: "（", with: "").replacingOccurrences(of: "）", with: ""))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("周期：\(String(conf.semesterStart.prefix(10))) 至 \(String(conf.semesterEnd.prefix(10)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - 表头
    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(width: width, height: viewModel.headerHeight)
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            .customBorder(width: 0.5, edges: [.bottom, .trailing], color: separatorColor)
    }

    // MARK: - 表格主体
    private var tableBody: some View {
        HStack(spacing: 0) {
            // 周次列
            VStack(spacing: 0) {
                headerCell("周", width: weekColWidth)
                ForEach(viewModel.weekSpans) { span in
                    Text(span.text)
                        .font(.caption)
                        .fontWeight(span.isCustom ? .bold : .regular)
                        .foregroundColor(span.isCustom ? .accentColor : .primary)
                        .frame(width: weekColWidth, height: viewModel.rowHeight * CGFloat(span.rowCount))
                        .background(span.isCustom ? Color.accentColor.opacity(0.1) : Color.clear)
                        .customBorder(width: 0.5, edges: [.bottom, .trailing], color: separatorColor)
                }
            }

            // 月份列
            VStack(spacing: 0) {
                headerCell("月", width: monthColWidth)
                ForEach(viewModel.monthSpans) { span in
                    Text(span.text)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .frame(width: monthColWidth, height: viewModel.rowHeight * CGFloat(span.rowCount))
                        .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.4))
                        .customBorder(width: 0.5, edges: [.bottom, .trailing], color: separatorColor)
                }
            }

            // 七天日期列
            ForEach(0..<7, id: \.self) { dayIndex in
                VStack(spacing: 0) {
                    headerCell(viewModel.dayNames[dayIndex], width: dayColWidth)
                    ForEach(0..<viewModel.weeks.count, id: \.self) { rowIndex in
                        dayCell(rowIndex: rowIndex, colIndex: dayIndex)
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
                                if #available(iOS 26.0, *) {
                                    view.glassEffect()
                                } else {
                                    view.background(.ultraThinMaterial, in: Capsule())
                                }
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
    private func dayCell(rowIndex: Int, colIndex: Int) -> some View {
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

        // 绘制内角修补块（核心逻辑：如果我的横竖都和我是同一个月，但对角线是别的月，说明我身处拐角内侧）
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

        let highlightColor = Color.accentColor

        return Text("\(dayData.day)")
            .font(.footnote)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundColor(dayData.isWeekend ? .red.opacity(0.8) : .primary)
            .frame(width: dayColWidth, height: viewModel.rowHeight)
            .customBorder(width: 0.5, edges: [.bottom, .trailing], color: separatorColor)
            .customBorder(width: 1.5, edges: thickEdges, color: highlightColor)
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
            // 专门用来修补“内拐角”缺口的小方块
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
