//
//  TimeSchedulePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct TimeSchedulePage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("课程统计")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(spacing: 15) {
                    StatCard(title: "总课程数", value: "\(data.totalCoursesCount)")
                    StatCard(title: "总学时", value: "\(data.totalStudyMinutes) 分钟")
                    StatCard(title: "早八次数", value: "\(data.earlyMorningCoursesCount)")
                    StatCard(title: "晚课次数", value: "\(data.eveningCoursesCount)")
                    StatCard(title: "周末上课次数", value: "\(data.weekendCoursesCount)")
                }
                .padding()
            }
        }
    }
}
