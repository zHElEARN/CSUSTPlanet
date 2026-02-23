//
//  DormElectricityEntryView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/20.
//

import Charts
import SwiftUI
import WidgetKit

struct DormElectricityEntryView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily

    var entry: DormElectricityProvider.Entry

    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd HH:mm"
        return dateFormatter
    }()

    // MARK: - Body

    var body: some View {
        Group {
            if let dorm = entry.configuration.dorm {
                VStack(spacing: 0) {
                    headerView(dorm: dorm, last: entry.last)
                    if family == .systemSmall || entry.last == nil {
                        Divider().padding(.vertical, 4)
                    }
                    contentView(last: entry.last, bounds: entry.bounds, records: entry.records)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                emptyView
            }
        }
        .widgetURL(URL(string: "csustplanet://widgets/electricity"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Empty View

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))
            VStack(spacing: 4) {
                Text("尚未选择宿舍")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("请长按当前小组件\n点击“编辑小组件”配置")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Header View

    func headerView(dorm: DormIntentEntity, last: DormElectricityEntry.Record?) -> some View {
        HStack(alignment: .center, spacing: 0) {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dorm.buildingName)
                        .font(.system(size: 14, weight: .medium))
                    Text(dorm.room)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(dorm.campusName) \(dorm.buildingName)")
                        .font(.system(size: 14, weight: .medium))
                    Text(dorm.room)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
                if let last = last {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.2f", last.electricity))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ColorUtil.electricityColor(electricity: last.electricity))
                            + Text("度")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("更新时间: \(dateFormatter.string(from: last.date))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 8)
                }
            }
            Button(intent: RefreshElectricityTimelineIntent()) {
                Image(systemName: "arrow.clockwise.circle")
            }
            .foregroundColor(.blue)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    func contentView(last: DormElectricityEntry.Record?, bounds: (min: Double, max: Double)?, records: [DormElectricityEntry.Record]) -> some View {
        if family == .systemSmall {
            if let last = last {
                textView(last: last)
            } else {
                noDataView
            }
        } else {
            if let bounds = bounds {
                chartView(bounds: bounds, records: records)
                    .padding(.top, 8)
            } else {
                noDataView
            }
        }
    }

    // MARK: - Text View

    @ViewBuilder
    func textView(last: DormElectricityEntry.Record) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            Text("剩余电量")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", last.electricity))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(ColorUtil.electricityColor(electricity: last.electricity))
                + Text("度")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text("更新时间: \(dateFormatter.string(from: last.date))")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    func chartView(bounds: (min: Double, max: Double), records: [DormElectricityEntry.Record]) -> some View {
        Chart(records) { record in
            LineMark(x: .value("日期", record.date), y: .value("电量", record.electricity))
                .interpolationMethod(.catmullRom)
                .symbol {
                    if records.count <= 1 {
                        Circle()
                            .frame(width: 8)
                            .foregroundStyle(.primary)
                    }
                }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYScale(domain: (bounds.min - 1)...(bounds.max + 1))
    }

    // MARK: - No Data View

    var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.slash.fill")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("暂无电量数据")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
