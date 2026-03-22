//
//  DormOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct DormOverviewView: View {
    @Bindable var viewModel: OverviewViewModel

    var body: some View {
        TrackLink(destination: DormListView()) {
            CustomGroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.yellow)
                        Spacer()
                        if let dorm = viewModel.primaryDorm {
                            Text(dorm.room)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let dorm = viewModel.primaryDorm, let lastFetchElectricity = dorm.lastFetchElectricity {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", lastFetchElectricity))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorUtil.electricityColor(electricity: lastFetchElectricity))
                                .minimumScaleFactor(0.7)

                            Text("kWh")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                        }

                        if let info = viewModel.electricityExhaustionInfo {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 130)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
