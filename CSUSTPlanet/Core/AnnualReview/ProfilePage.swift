//
//  ProfilePage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct ProfilePage: View {
    let data: AnnualReviewData

    var startAnimation: Bool

    var onAnimationEnd: () -> Void

    @State private var showTitle = false
    @State private var showList = false

    @State private var hasAnimated = false

    var body: some View {
        VStack(spacing: 20) {
            Text("个人信息")
                .font(.largeTitle)
                .bold()
                .padding(.top)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)

            VStack(alignment: .leading, spacing: 10) {
                Group {
                    AnnualInfoRow(label: "姓名", value: data.name)
                    AnnualInfoRow(label: "拼音", value: data.namePinyin)
                    AnnualInfoRow(label: "学号", value: data.studentID)
                    AnnualInfoRow(label: "院系", value: data.department)
                    AnnualInfoRow(label: "专业", value: data.major)
                    AnnualInfoRow(label: "班级", value: data.className)
                    AnnualInfoRow(label: "入学日期", value: data.enrollmentDate)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .padding()
            .opacity(showList ? 1 : 0)
            .scaleEffect(showList ? 1 : 0.95)

            Spacer()
        }
        .onChange(of: startAnimation) { _, newValue in
            if newValue && !hasAnimated {
                performAnimation()
            }
        }
        .onAppear {
            if startAnimation && !hasAnimated {
                performAnimation()
            }
        }
    }

    private func performAnimation() {
        hasAnimated = true

        withAnimation(.easeOut(duration: 0.5)) {
            showTitle = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
            showList = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onAnimationEnd()
        }
    }
}
