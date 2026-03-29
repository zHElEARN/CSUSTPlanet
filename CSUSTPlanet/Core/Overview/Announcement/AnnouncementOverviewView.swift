//
//  AnnouncementOverviewView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import CSUSTKit
import SwiftUI

struct AnnouncementOverviewView: View {
    @State private var viewModel = AnnouncementListViewModel()
    @Namespace private var namespace
    @State private var refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000)

    var body: some View {
        Group {
            #if os(macOS)
            TrackLink(destination: AnnouncementListView(viewModel: viewModel)) {
                CustomGroupBox {
                    cardContent
                }
            }
            #elseif os(iOS)
            if #available(iOS 18.0, macOS 15.0, *) {
                TrackLink(
                    destination: AnnouncementListView(viewModel: viewModel)
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
                TrackLink(destination: AnnouncementListView(viewModel: viewModel)) {
                    CustomGroupBox {
                        cardContent
                    }
                }
            }
            #endif
        }
        .task { await viewModel.loadInitial(showError: false) }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("App公告")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                if viewModel.hasLoadedAnnouncements && viewModel.unreadAnnouncementsCount > 0 {
                    Text("\(viewModel.unreadAnnouncementsCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(.red, in: .capsule)
                }

                Spacer()

                if viewModel.hasLoadedAnnouncements && viewModel.unreadAnnouncementsCount > 0 {
                    Button {
                        viewModel.markAllAsRead()
                    } label: {
                        Text("全部已读")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "megaphone.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)

                Text(viewModel.unreadAnnouncementsCount > 0 ? "\(viewModel.unreadAnnouncementsCount) 条未读公告" : "无未读公告")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .redacted(reason: viewModel.hasLoadedAnnouncements ? [] : .placeholder)
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
