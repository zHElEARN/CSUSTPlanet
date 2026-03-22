//
//  OverviewComponents.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewSectionHeader<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination

    var body: some View {
        TrackLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Spacer()

                HStack(spacing: 4) {
                    Text("查看全部")
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct OverviewEmptyStateView: View {
    let icon: String
    let text: String

    var body: some View {
        CustomGroupBox {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
