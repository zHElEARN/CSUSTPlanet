//
//  AnnouncementListView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import SwiftUI

struct AnnouncementListView: View {
    @State private var viewModel = AnnouncementListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoadingAnnouncements && viewModel.announcements.isEmpty {
                ProgressView("加载公告中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.sortedAnnouncements.isEmpty {
                ContentUnavailableView(
                    "暂无公告",
                    systemImage: "megaphone",
                    description: Text("当前没有可展示的公告内容")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.sortedAnnouncements) { announcement in
                            announcementCard(announcement)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                }
            }
        }
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadAnnouncements() }
        .errorToast($viewModel.errorToast)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("全部已读") {
                    viewModel.markAllAsRead()
                }
                .disabled(viewModel.unreadAnnouncementsCount == 0)
            }
        }
        .navigationTitle("App公告")
        .navigationSubtitleCompat("共\(viewModel.announcements.count)条公告")
        .trackView("AnnouncementList")
    }

    @ViewBuilder
    private func announcementCard(_ announcement: Announcement) -> some View {
        let contentText = announcement.content.trimmingCharacters(in: .whitespacesAndNewlines)

        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            if announcement.isBanner {
                                Text("置顶")
                                    .font(.caption.bold())
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            if viewModel.isUnread(announcement) {
                                Text("未读")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.12))
                                    .clipShape(Capsule())
                            }

                            Text(announcement.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if announcement.isBanner {
                        Image(systemName: "pin.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                }

                if !contentText.isEmpty {
                    Divider()

                    Text(contentText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }

                Text("发布于：\(viewModel.relativeCreatedAtText(for: announcement))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        AnnouncementListView()
    }
}
