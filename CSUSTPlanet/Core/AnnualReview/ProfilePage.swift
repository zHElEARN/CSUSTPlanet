//
//  ProfilePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct ProfilePage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("个人信息")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    AnnualInfoRow(label: "姓名", value: data.name)
                    AnnualInfoRow(label: "拼音", value: data.namePinyin)
                    AnnualInfoRow(label: "学号", value: data.studentID)
                    AnnualInfoRow(label: "院系", value: data.department)
                    AnnualInfoRow(label: "专业", value: data.major)
                    AnnualInfoRow(label: "班级", value: data.className)
                    AnnualInfoRow(label: "入学日期", value: data.enrollmentDate)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
        }
    }
}
