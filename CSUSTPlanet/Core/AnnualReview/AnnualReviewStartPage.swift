//
//  AnnualReviewStartPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct AnnualReviewStartPage: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("2025年")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.primary)

                Text("年度总结报告")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text("长理星球")
                    .font(.headline)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(spacing: 8) {
                Text("向下滑动开启")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    AnnualReviewStartPage()
}
