//
//  DormOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftData
import SwiftUI

struct DormOverviewView: View {
    let primaryDorm: Dorm?
    let exhaustionInfo: String?

    var body: some View {
        TrackLink(destination: ElectricityQueryView()) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Spacer()
                    if let dorm = primaryDorm {
                        Text(dorm.room)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let dorm = primaryDorm, let record = dorm.lastRecord {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", record.electricity))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(ColorUtil.electricityColor(electricity: record.electricity))

                        Text("kWh")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    if let info = exhaustionInfo {
                        Text(info)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("未绑定")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("添加宿舍")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(16)
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
