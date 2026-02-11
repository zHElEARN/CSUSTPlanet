//
//  DormPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct DormPage: View {
    let data: AnnualReviewData

    var body: some View {
        VStack(spacing: 20) {
            Text("宿舍生活")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            ForEach(data.dormElectricityStats) { stat in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(stat.campusName) \(stat.buildingName) \(stat.room)")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("查询: \(stat.queryCount) 次")
                            Text("充电: \(stat.chargeCount) 次")
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("最高: \(String(format: "%.1f", stat.maxElectricity))")
                            Text("最低: \(String(format: "%.1f", stat.minElectricity))")
                        }
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

            if data.dormElectricityStats.isEmpty {
                Text("暂无宿舍数据")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}
