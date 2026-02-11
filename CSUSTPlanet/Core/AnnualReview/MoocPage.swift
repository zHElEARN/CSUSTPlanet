//
//  MoocPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct MoocPage: View {
    let data: AnnualReviewData

    var body: some View {
        VStack(spacing: 20) {
            Text("网络课程中心")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            VStack(spacing: 15) {
                if let totalOnlineMinutes = data.moocTotalOnlineMinutes, let loginCount = data.moocLoginCount {
                    StatCard(title: "总在线时长", value: "\(totalOnlineMinutes) 分钟")
                    StatCard(title: "登录次数", value: "\(loginCount) 次")
                } else {
                    Text("暂无数据")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Spacer()
        }
    }
}
