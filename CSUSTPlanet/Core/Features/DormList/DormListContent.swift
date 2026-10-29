//
//  DormListContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/29.
//

import CSUSTKit
import SwiftUI

struct DormListContent: View {
    let dorms: [DormGRDB]
    let exhaustionInfoMap: [Int64: String]
    let isLoading: Bool
    let queryingDormIDs: Set<Int64>

    @Binding var errorToast: ToastState

    let onAddDorm: (CampusCardHelper.Room) -> Void
    let onDeleteDorm: (DormGRDB) -> Void
    let onToggleFavorite: (DormGRDB) -> Void
    let onQuery: (DormGRDB) async -> Void

    @State private var isAddDormPresented = false
    @State private var targetDeleteDorm: DormGRDB?

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if dorms.isEmpty {
                ContentUnavailableView("暂无宿舍", systemImage: "building.2", description: Text("点击右上角添加宿舍"))
            } else {
                #if os(macOS)
                CustomScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dorms) { dorm in
                            dormCard(dorm)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 6)
                }
                #elseif os(iOS)
                List {
                    ForEach(dorms) { dorm in
                        dormCard(dorm)
                            .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                #endif
            }
        }
        .navigationTitle("宿舍列表")
        .navigationSubtitleCompat("共\(dorms.count)个宿舍")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isAddDormPresented = true }) {
                    Label("添加宿舍", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddDormPresented) {
            AddDormView { room in
                onAddDorm(room)
            }
            .presentationDetents([.medium, .large])
        }
        .alert("删除宿舍", isPresented: deleteAlertBinding) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                guard let targetDeleteDorm else { return }
                onDeleteDorm(targetDeleteDorm)
                self.targetDeleteDorm = nil
            }
        } message: {
            if let targetDeleteDorm {
                Text("确定要删除 \(targetDeleteDorm.buildingName) \(targetDeleteDorm.room) 吗？")
            }
        }
        .errorToast($errorToast)
    }

    // MARK: - Dorm Card

    @ViewBuilder
    private func dormCard(_ dorm: DormGRDB) -> some View {
        let electricityColor: Color = {
            guard let electricity = dorm.lastFetchElectricity else { return .secondary }
            return ColorUtil.electricityColor(electricity: electricity)
        }()

        if let dormID = dorm.id {
            Group {
                #if os(macOS)
                NavigationLink(value: AppRoute.features(.dormList(.detail(DormParams(dormID: dormID))))) {
                    CustomGroupBox {
                        dormCardContent(dorm, electricityColor: electricityColor)
                    }
                }
                .buttonStyle(.plain)
                #elseif os(iOS)
                ZStack {
                    NavigationLink(value: AppRoute.features(.dormList(.detail(DormParams(dormID: dormID))))) {
                        EmptyView()
                    }
                    .opacity(0)

                    CustomGroupBox {
                        dormCardContent(dorm, electricityColor: electricityColor)
                    }
                }
                #endif
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(asyncAction: { await onQuery(dorm) }) {
                    Label("查询", systemImage: "bolt.fill")
                }
                .tint(.yellow)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(action: { targetDeleteDorm = dorm }) {
                    Label("删除", systemImage: "trash")
                }
                .tint(.red)
            }
            .contextMenu {
                Button(action: { onToggleFavorite(dorm) }) {
                    Label(dorm.isFavorite ? "取消收藏" : "收藏宿舍", systemImage: dorm.isFavorite ? "star.slash" : "star")
                }

                Button(asyncAction: { await onQuery(dorm) }) {
                    Label("查询电量", systemImage: "bolt")
                }
                .disabled(isQuerying(dorm))

                Button(role: .destructive, action: { targetDeleteDorm = dorm }) {
                    Label("删除宿舍", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Dorm Card Content

    @ViewBuilder
    private func dormCardContent(_ dorm: DormGRDB, electricityColor: Color) -> some View {
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

            VStack(alignment: .trailing, spacing: 8) {
                Button(asyncAction: { await onQuery(dorm) }) {
                    if isQuerying(dorm) {
                        ProgressView()
                            .smallControlSizeOnMac()
                            .frame(width: 15, height: 15)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 15, height: 15)
                    }
                }
                .buttonStyle(.plain)
                .disabled(isQuerying(dorm))

                Spacer()

                if let lastFetchDate = dorm.lastFetchDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        LastUpdatedDateView(
                            lastUpdated: lastFetchDate,
                            font: .caption,
                            foregroundStyle: .tertiary
                        )

                        if let dormID = dorm.id, let info = exhaustionInfoMap[dormID] {
                            Text(info)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func isQuerying(_ dorm: DormGRDB) -> Bool {
        guard let dormID = dorm.id else { return false }
        return queryingDormIDs.contains(dormID)
    }

    private var deleteAlertBinding: Binding<Bool> {
        .init(
            get: { targetDeleteDorm != nil },
            set: { newValue in
                if !newValue { targetDeleteDorm = nil }
            }
        )
    }
}
