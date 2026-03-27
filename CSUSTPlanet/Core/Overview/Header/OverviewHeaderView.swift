//
//  OverviewHeaderView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewHeaderView: View {
    @State private var viewModel = OverviewHeaderViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(Date().formatted(.dateTime.month().day().weekday()))
                if let weekInfo = viewModel.weekInfo {
                    Text("·")
                    Text(weekInfo)
                }
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 10)
        .onAppear(perform: viewModel.onAppear)
    }
}
