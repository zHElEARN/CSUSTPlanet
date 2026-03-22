//
//  DormHistoryView.swift
//  CSUSTPlanet
//
//  Created by OpenCode on 2026/3/22.
//

import SwiftUI

struct DormHistoryView: View {
    @Bindable var viewModel: DormDetailViewModel

    var body: some View {
        Form {
            if viewModel.sortedRecords.isEmpty {
                ContentUnavailableView("无历史记录", systemImage: "bolt.slash", description: Text("点击详情页的刷新按钮获取最新电量"))
            } else {
                ForEach(viewModel.sortedRecords) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(String(format: "%.2f", record.electricity)) kWh")
                                .font(.headline)
                                .monospacedDigit()
                                .foregroundStyle(ColorUtil.electricityColor(electricity: record.electricity))

                            Text(record.date.formatted(date: .numeric, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.deleteRecord(record)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("历史记录")
        .navigationSubtitleCompat("共\(viewModel.sortedRecords.count)条记录")
        .errorToast($viewModel.errorToast)
        .trackView("DormHistory")
    }
}
