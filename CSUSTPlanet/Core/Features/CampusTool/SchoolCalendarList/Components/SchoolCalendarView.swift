//
//  SchoolCalendarView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import Alamofire
import SwiftUI

// MARK: - 配置文件模型

private struct ConfigData: Codable {
    let semesterCode: String
    let title: String
    let subtitle: String
    let calendarStart: String
    let calendarEnd: String
    let semesterStart: String
    let semesterEnd: String
    let notes: [NoteConfig]
    let customWeekRanges: [CustomWeekRange]
}

private struct NoteConfig: Codable {
    let row: Int
    let content: String
    let needNumber: Bool?
}

private struct CustomWeekRange: Codable {
    let startRow: Int
    let endRow: Int
    let content: String
}

// MARK: - 视图渲染用到的数据模型

private struct DayData: Identifiable {
    let id = UUID()
    let day: Int
    let isWeekend: Bool
    let monthKey: String
}

private struct WeekRow: Identifiable {
    let id: Int
    let month: Int
    var computedWeekNumber: Int?
    var days: [DayData]
}

private struct SpanData: Identifiable {
    let id = UUID()
    let text: String
    let rowCount: Int
    let isCustom: Bool
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

// MARK: - ViewModel
@Observable
private class SchoolCalendarViewModel {
    var config: ConfigData?
    var weeks: [WeekRow] = []
    var weekSpans: [SpanData] = []
    var monthSpans: [SpanData] = []
    var notes: [String] = []

    var isLoading: Bool = false
    var isShowingError: Bool = false
    var errorMessage: String = ""

    // 固定尺寸
    let headerHeight: CGFloat = 36
    let rowHeight: CGFloat = 46
    let dayNames = ["日", "一", "二", "三", "四", "五", "六"]

    private let monthNames = [
        1: "一月", 2: "二月", 3: "三月", 4: "四月",
        5: "五月", 6: "六月", 7: "七月", 8: "八月",
        9: "九月", 10: "十月", 11: "十一月", 12: "十二月",
    ]

    private let circleNumbers = ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]

    @MainActor
    func loadConfig(semester: String) async {
        isLoading = true
        isShowingError = false

        do {
            let decodedConfig = try await AF.request("\(Constants.backendHost)/config/semester-calendars/\(semester)")
                .serializingDecodable(ConfigData.self).value
            self.config = decodedConfig
            generateCalendar(from: decodedConfig)
        } catch {
            debugPrint(error)
            self.isShowingError = true
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func generateCalendar(from config: ConfigData) {
        let fmt = ISO8601DateFormatter()

        guard let startDate = fmt.date(from: config.calendarStart),
            let endDate = fmt.date(from: config.calendarEnd),
            let semesterStart = fmt.date(from: config.semesterStart),
            let semesterEnd = fmt.date(from: config.semesterEnd)
        else { return }

        let cal = Calendar.current

        let semStartWeekday = cal.component(.weekday, from: semesterStart)
        let semStartSunday = cal.date(byAdding: .day, value: -(semStartWeekday - 1), to: semesterStart)!

        let semEndWeekday = cal.component(.weekday, from: semesterEnd)
        let semEndSaturday = cal.date(byAdding: .day, value: 7 - semEndWeekday, to: semesterEnd)!

        var currentTemp = startDate
        var tempWeeks: [WeekRow] = []
        var rowIdx = 1

        while currentTemp <= endDate {
            let currentWeekSunday = currentTemp
            let currentWeekSaturday = cal.date(byAdding: .day, value: 6, to: currentTemp)!

            var weekInfo = WeekRow(id: rowIdx, month: cal.component(.month, from: currentTemp), computedWeekNumber: nil, days: [])

            if currentWeekSaturday >= semStartSunday && currentWeekSunday <= semEndSaturday {
                let diff = cal.dateComponents([.day], from: semStartSunday, to: currentWeekSunday).day ?? 0
                weekInfo.computedWeekNumber = (diff / 7) + 1
            }

            for i in 0..<7 {
                let isWeekend = (i == 0 || i == 6)
                let yyyy = cal.component(.year, from: currentTemp)
                let mm = String(format: "%02d", cal.component(.month, from: currentTemp))

                weekInfo.days.append(
                    DayData(
                        day: cal.component(.day, from: currentTemp),
                        isWeekend: isWeekend,
                        monthKey: "\(yyyy)-\(mm)"
                    ))
                currentTemp = cal.date(byAdding: .day, value: 1, to: currentTemp)!
            }
            tempWeeks.append(weekInfo)
            rowIdx += 1
        }
        self.weeks = tempWeeks

        var tempWeekSpans: [SpanData] = []
        var r = 1
        while r <= tempWeeks.count {
            if let custom = config.customWeekRanges.first(where: { $0.startRow == r }) {
                let rowCount = custom.endRow - custom.startRow + 1
                tempWeekSpans.append(SpanData(text: custom.content, rowCount: rowCount, isCustom: true))
                r = custom.endRow + 1
            } else {
                let text = tempWeeks[r - 1].computedWeekNumber != nil ? "\(tempWeeks[r-1].computedWeekNumber!)" : ""
                tempWeekSpans.append(SpanData(text: text, rowCount: 1, isCustom: false))
                r += 1
            }
        }
        self.weekSpans = tempWeekSpans

        var tempMonthSpans: [SpanData] = []
        if !tempWeeks.isEmpty {
            var currentMonth = tempWeeks[0].month
            var currentCount = 0
            for week in tempWeeks {
                if week.month == currentMonth {
                    currentCount += 1
                } else {
                    tempMonthSpans.append(SpanData(text: monthNames[currentMonth] ?? "", rowCount: currentCount, isCustom: false))
                    currentMonth = week.month
                    currentCount = 1
                }
            }
            if currentCount > 0 {
                tempMonthSpans.append(SpanData(text: monthNames[currentMonth] ?? "", rowCount: currentCount, isCustom: false))
            }
        }
        self.monthSpans = tempMonthSpans

        var tempNotes = Array(repeating: "", count: tempWeeks.count)
        var sequenceNumber = 1

        for note in config.notes {
            let rIndex = note.row - 1
            if rIndex >= 0 && rIndex < tempWeeks.count {
                var text = note.content
                if note.needNumber == true {
                    let prefix = sequenceNumber <= 10 ? circleNumbers[sequenceNumber - 1] : "\(sequenceNumber)"
                    text = "\(prefix) \(text)"
                    sequenceNumber += 1
                }
                tempNotes[rIndex] = text
            }
        }
        self.notes = tempNotes
    }
}

// MARK: - SchoolCalendarView
struct SchoolCalendarView: View {
    let semester: String

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
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
                            )
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
        .navigationTitle(viewModel.config?.title ?? "校历")
        .task {
            if viewModel.config == nil && !viewModel.isLoading && !viewModel.isShowingError {
                await viewModel.loadConfig(semester: semester)
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
