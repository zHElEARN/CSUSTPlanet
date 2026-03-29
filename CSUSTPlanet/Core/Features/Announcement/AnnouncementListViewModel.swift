//
//  AnnouncementListViewModel.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/29.
//

import Foundation
import Observation

typealias Announcement = PlanetConfigService.Announcement

@MainActor
@Observable
final class AnnouncementListViewModel {
    var announcements: [Announcement] = []
    var errorToast: ToastState = .errorTitle
    var isLoadingAnnouncements: Bool = false
    var readAnnouncementIDs: Set<String> = Set(MMKVHelper.Announcement.readIDs)

    private var hasLoadedInitial = false

    func loadInitial() async {
        guard !hasLoadedInitial else { return }
        hasLoadedInitial = true
        await loadAnnouncements()
    }

    func loadAnnouncements() async {
        guard !isLoadingAnnouncements else { return }
        isLoadingAnnouncements = true
        defer { isLoadingAnnouncements = false }

        do {
            announcements = try await PlanetConfigService.announcements()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    var sortedAnnouncements: [Announcement] {
        announcements.sorted(by: compareAnnouncements)
    }

    var unreadAnnouncementsCount: Int {
        sortedAnnouncements.filter(isUnread).count
    }

    func relativeCreatedAtText(for announcement: Announcement) -> String {
        DateUtil.relativeTimeString(for: announcement.createdAt)
    }

    func isUnread(_ announcement: Announcement) -> Bool {
        !readAnnouncementIDs.contains(announcement.id)
    }

    func markAllAsRead() {
        readAnnouncementIDs.formUnion(announcements.map(\.id))
        MMKVHelper.Announcement.readIDs = Array(readAnnouncementIDs)
    }

    private func compareAnnouncements(_ lhs: Announcement, _ rhs: Announcement) -> Bool {
        if lhs.isBanner != rhs.isBanner {
            return lhs.isBanner && !rhs.isBanner
        }

        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }

        return lhs.id > rhs.id
    }
}

extension MMKVHelper {
    enum Announcement {
        @MMKVStorage(key: "Announcement.readIDs", defaultValue: [])
        static var readIDs: [String]
    }
}
