//
//  DormHistoryContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/29.
//

import SwiftUI

struct DormHistoryContent: View {
    let records: [ElectricityRecordGRDB]
    @Binding var errorToast: ToastState
    let onDelete: (ElectricityRecordGRDB) -> Void

    var body: some View {
        Form {
            if records.isEmpty {
                ContentUnavailableView("无近三个月历史记录", systemImage: "bolt.slash", description: Text("点击详情页的刷新按钮获取最新电量"))
            } else {
                ForEach(records) { record in
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
                                onDelete(record)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button {
                            withAnimation {
                                onDelete(record)
                            }
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("近三个月历史记录")
        .navigationSubtitleCompat("共\(records.count)条记录")
        .errorToast($errorToast)
    }
}
