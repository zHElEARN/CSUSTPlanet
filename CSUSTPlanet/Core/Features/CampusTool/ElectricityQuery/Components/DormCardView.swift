//
//  DormCardView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import AlertToast
import Charts
import SwiftData
import SwiftUI

struct DormCardView: View {
    @State var viewModel = DormElectricityViewModel()
    @Bindable var dorm: Dorm

    private var electricityColor: Color {
        guard let electricity = dorm.lastFetchElectricity else { return .primary }
        return ColorUtil.electricityColor(electricity: electricity)
    }

    // MARK: - Body

    var body: some View {
        Group {
            #if os(macOS)
            TrackLink(destination: DormDetailView(viewModel: viewModel, dorm: dorm)) {
                cardContent
            }
            .buttonStyle(.plain)
            #elseif os(iOS)
            ZStack {
                TrackLink(destination: DormDetailView(viewModel: viewModel, dorm: dorm)) {
                    EmptyView()
                }
                .opacity(0)

                cardContent
            }
            #endif
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                Label("查询", systemImage: "bolt.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(action: { viewModel.isConfirmationDialogPresented = true }) {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(action: { viewModel.isConfirmationDialogPresented = true }) {
                Label("删除宿舍", systemImage: "trash")
                    .tint(.red)
            }
            Button(action: { viewModel.toggleFavorite(dorm) }) {
                Label(dorm.isFavorite ? "取消收藏" : "设为常用", systemImage: dorm.isFavorite ? "star.slash" : "star")
            }
            Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                Label("查询电量", systemImage: "bolt.fill")
            }
            .disabled(viewModel.isQueryingElectricity)
            Divider()
            Menu {
                Button(action: { viewModel.isShowNotificationSettings = true }) {
                    Label("设置定时查询", systemImage: "bell")
                }
                .disabled(viewModel.isScheduleLoading || dorm.scheduleEnabled)
                Button(action: { viewModel.isCancelScheduleAlertPresented = true }) {
                    Label("取消定时查询", systemImage: "bell.slash").tint(.red)
                }
                .disabled(viewModel.isScheduleLoading || !dorm.scheduleEnabled)
            } label: {
                Label("定时查询", systemImage: "clock")
            }
        }
        .alert("删除宿舍", isPresented: $viewModel.isConfirmationDialogPresented) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive, action: { viewModel.deleteDorm(dorm) })
        } message: {
            Text("确定要删除 \(dorm.room) 宿舍吗？")
        }
        .errorToast($viewModel.errorToast)
        .alert("取消定时查询", isPresented: $viewModel.isCancelScheduleAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) { viewModel.removeSchedule(dorm) }
        } message: {
            Text("确定要取消定时查询吗？")
        }
        .sheet(isPresented: $viewModel.isShowNotificationSettings) {
            DormNotificationSettingsView(
                isPresented: $viewModel.isShowNotificationSettings,
                onConfirm: { hour, minute in
                    viewModel.handleNotificationSettings(dorm, scheduleHour: hour, scheduleMinute: minute)
                }
            )
        }
    }

    // MARK: - Card Content

    @ViewBuilder
    private var cardContent: some View {
        CustomGroupBox {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Text(dorm.room)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        if dorm.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }

                        if dorm.scheduleEnabled {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                    }

                    if let electricity = dorm.lastFetchElectricity {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", electricity))
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(electricityColor)
                                .contentTransition(.numericText())

                            Text("kWh")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 2)
                        }
                    } else {
                        Text("暂无数据")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }

                    Text("\(dorm.campusName) · \(dorm.buildingName)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Button(action: { viewModel.handleQueryElectricity(dorm) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(viewModel.isQueryingElectricity ? Color.secondary : .blue)
                            .rotationEffect(.degrees(viewModel.isQueryingElectricity ? 360 : 0))
                            .animation(viewModel.isQueryingElectricity ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isQueryingElectricity)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    if let lastFetchDate = dorm.lastFetchDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("更新于 " + lastFetchDate.formatted(.relative(presentation: .named)))
                            if let info = ElectricityUtil.getExhaustionInfo(from: dorm.records) {
                                Text(info)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}
