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
                StatCard(title: "总在线时长", value: "\(data.moocTotalOnlineMinutes ?? 0) 分钟")
                StatCard(title: "登录次数", value: "\(data.moocLoginCount ?? 0) 次")
            }
            .padding()

            Spacer()
        }
    }
}
