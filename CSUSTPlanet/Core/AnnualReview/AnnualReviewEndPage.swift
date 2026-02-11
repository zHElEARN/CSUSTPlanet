//
//  AnnualReviewEndPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import SwiftUI

struct AnnualReviewEndPage: View {
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("2026")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.primary)

                Text("明年见")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text("长理星球")
                    .font(.headline)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    AnnualReviewEndPage()
}
