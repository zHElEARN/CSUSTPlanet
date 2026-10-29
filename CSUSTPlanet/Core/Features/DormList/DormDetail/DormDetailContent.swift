//
//  DormDetailContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/29.
//

import Charts
import SwiftUI

struct DormDetailContent: View {
    let params: DormParams
    let dorm: DormGRDB
    let sortedRecords: [ElectricityRecordGRDB]
    let chartRecords: [ElectricityRecordGRDB]
    let chartYDomain: ClosedRange<Double>
    let exhaustionInfo: String?
    let isQueryingElectricity: Bool

    @Binding var errorToast: ToastState

    let onQuery: () async -> Void
    let onToggleFavorite: () -> Void
    let onDeleteRecord: (ElectricityRecordGRDB) -> Void
    let onDeleteAllRecords: () -> Void

    @State private var isDeleteAllRecordsAlertPresented = false

    // MARK: - Body

    var body: some View {
        CustomScrollView {
            VStack(spacing: 20) {
                electricityDashboardCard
                quickActionsGrid

                if !sortedRecords.isEmpty {
                    electricityTrendCard
                }

                dormInfoCard
                historyEntryButton

                if !sortedRecords.isEmpty {
                    clearHistoryButton
                }
            }
            .padding()
        }
        .navigationTitle("宿舍详情")
        .navigationSubtitleCompat("\(dorm.buildingName) \(dorm.room)")
        .alert("清除记录", isPresented: $isDeleteAllRecordsAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) {
                withAnimation {
                    onDeleteAllRecords()
                }
            }
        } message: {
            Text("此操作将删除该宿舍所有的历史电量记录且无法恢复，确定要继续吗？")
        }
        .errorToast($errorToast)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var electricityDashboardCard: some View {
        CustomGroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("剩余电量")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let lastFetchDate = dorm.lastFetchDate {
                        LastUpdatedDateView(
                            lastUpdated: lastFetchDate,
                            font: .caption,
                            foregroundStyle: .tertiary
                        )
                        .contentTransition(.numericText())
                    }
                }

                if let electricity = dorm.lastFetchElectricity {
                    VStack {
                        HStack(alignment: .lastTextBaseline) {
                            Text(String(format: "%.2f", electricity))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorUtil.electricityColor(electricity: electricity))
                                .contentTransition(.numericText())

                            Text("kWh")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                                .padding(.bottom, 6)
                        }

                        if let exhaustionInfo {
                            Text(exhaustionInfo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("--.--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }
        }
        .animation(.snappy, value: dorm.lastFetchElectricity)
        .animation(.snappy, value: dorm.lastFetchDate)
    }

    @ViewBuilder
    private var quickActionsGrid: some View {
        HStack(spacing: 12) {
            actionButton(
                icon: isQueryingElectricity ? "bolt.badge.clock" : "bolt.fill",
                title: isQueryingElectricity ? "查询中..." : "刷新电量",
                titleColor: .white,
                iconColor: .white,
                backgroundColor: AnyShapeStyle(Color.accentColor.gradient),
                asyncAction: { await onQuery() }
            )
            .disabled(isQueryingElectricity)

            actionButton(
                icon: dorm.isFavorite ? "star.fill" : "star",
                title: dorm.isFavorite ? "已收藏" : "收藏",
                titleColor: .primary,
                iconColor: dorm.isFavorite ? .yellow : .primary,
                asyncAction: { onToggleFavorite() }
            )
            .symbolEffect(.bounce.byLayer, value: dorm.isFavorite)
        }
    }

    @ViewBuilder
    private func actionButton(
        icon: String,
        title: String,
        titleColor: Color,
        iconColor: Color,
        backgroundColor: AnyShapeStyle? = nil,
        asyncAction: @escaping () async -> Void
    ) -> some View {
        Button(asyncAction: asyncAction) {
            if let backgroundColor {
                actionButtonContent(icon: icon, title: title, titleColor: titleColor, iconColor: iconColor)
                    .frame(maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 15).fill(backgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            } else {
                CustomGroupBox {
                    actionButtonContent(icon: icon, title: title, titleColor: titleColor, iconColor: iconColor)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
    }

    @ViewBuilder
    private func actionButtonContent(icon: String, title: String, titleColor: Color, iconColor: Color) -> some View {
        VStack(spacing: 6) {
            Group {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }
            .frame(height: 28)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var dormInfoCard: some View {
        CustomGroupBox {
            VStack(spacing: 12) {
                infoRow(icon: "house.fill", color: .blue, title: "宿舍", value: dorm.room)
                infoRow(icon: "building.2.fill", color: .green, title: "楼栋", value: dorm.buildingName)
                infoRow(icon: "map.fill", color: .orange, title: "校区", value: dorm.campusName)
            }
        }
    }

    @ViewBuilder
    private var electricityTrendCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Label("近三个月电量趋势", systemImage: "chart.xyaxis.line")
                    .font(.headline)

                Chart(chartRecords) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("电量", record.electricity)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.linear)
                    .symbol {
                        if chartRecords.count < 15 {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8)
                        }
                    }
                }
                .chartYScale(domain: chartYDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 220)
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
        }
    }

    @ViewBuilder
    private var historyEntryButton: some View {
        NavigationLink(value: AppRoute.features(.dormList(.detail(params, .history(params))))) {
            CustomGroupBox {
                HStack {
                    Label("查看近三个月历史记录", systemImage: "list.bullet.clipboard")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var clearHistoryButton: some View {
        Button(role: .destructive) {
            isDeleteAllRecordsAlertPresented = true
        } label: {
            Text("清除所有历史记录")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }

    private func infoRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
