//
//  SpacePeoplePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import CSUSTKit
import SwiftUI

struct SpacePeoplePage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("常去地点与老师")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("上课常去地点 TOP")
                        .font(.headline)
                    RankingView(ranking: data.buildingFrequency, suffix: "次")

                    Divider()

                    Text("每日课程分布")
                        .font(.headline)
                    ClassFrequencyView(frequency: data.dailyClassFrequency)

                    Divider()

                    Text("上课常去老师 TOP")
                        .font(.headline)
                    RankingView(ranking: data.teacherRanking, suffix: "次")
                }
                .padding()
            }
        }
    }
}
