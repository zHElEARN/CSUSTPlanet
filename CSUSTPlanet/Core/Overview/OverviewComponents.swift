//
//  OverviewComponents.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct HomeHeaderView: View {
    let weekInfo: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(Date().formatted(.dateTime.month().day().weekday()))
                if let weekInfo {
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
    }
}

struct HomeSectionHeader<Destination: View>: View {
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

struct HomeEmptyStateView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
