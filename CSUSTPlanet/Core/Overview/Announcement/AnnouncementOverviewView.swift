//
//  AnnouncementOverviewView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import CSUSTKit
import SwiftUI

struct AnnouncementOverviewView: View {
    @State private var viewModel = AnnouncementOverviewViewModel()
    @Namespace private var namespace
    @State private var refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000)

    var body: some View {
        Group {
            #if os(macOS)
            TrackLink(destination: AnnouncementListView()) {
                CustomGroupBox {
                    cardContent
                }
            }
            #elseif os(iOS)
            if #available(iOS 18.0, macOS 15.0, *) {
                TrackLink(
                    destination: AnnouncementListView()
                        .navigationTransition(.zoom(sourceID: "announcementList", in: namespace))
                        .onDisappear { refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000) }
                ) {
                    CustomGroupBox {
                        cardContent
                            .matchedTransitionSource(id: "announcementList", in: namespace)
                    }
                }
                .id(refreshID)
            } else {
                TrackLink(destination: AnnouncementListView()) {
                    CustomGroupBox {
                        cardContent
                    }
                }
            }
            #endif
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.title)
                .font(.title3)
                .fontWeight(.bold)
                .fontDesign(.rounded)

            HStack(spacing: 12) {
                Image(systemName: "megaphone.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Text(viewModel.linkText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        AnnouncementOverviewView()
            .padding()
    }
}
