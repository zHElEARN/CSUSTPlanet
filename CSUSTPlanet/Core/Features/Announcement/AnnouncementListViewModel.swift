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
final class AnnouncementListViewModel: Hashable {
    var announcements: [Announcement] = []
    var errorToast: ToastState = .errorTitle
    var isLoadingAnnouncements: Bool = false
    var hasLoadedAnnouncements: Bool = false
    var readAnnouncementIDs: Set<String> = Set(MMKVHelper.Announcement.readIDs)

    @ObservationIgnored private var isInitial = false

    func loadInitial(showError: Bool = true) async {
        guard !isInitial else { return }
        isInitial = true
        await loadAnnouncements(showError: showError)
    }

    func loadAnnouncements(showError: Bool = true) async {
        guard !isLoadingAnnouncements else { return }
        isLoadingAnnouncements = true
        defer { isLoadingAnnouncements = false }

        do {
            announcements = try await PlanetConfigService.announcements()
            GlobalManager.shared.unreadAnnouncementsCount = unreadAnnouncementsCount
            hasLoadedAnnouncements = true
        } catch {
            if showError {
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    var sortedAnnouncements: [Announcement] {
        announcements.sorted(by: compareAnnouncements)
    }

    var unreadAnnouncementsCount: Int {
        sortedAnnouncements.filter(isUnread).count
    }

    func isUnread(_ announcement: Announcement) -> Bool {
        !readAnnouncementIDs.contains(announcement.id)
    }

    func markAllAsRead() {
        readAnnouncementIDs.formUnion(announcements.map(\.id))
        MMKVHelper.Announcement.readIDs = Array(readAnnouncementIDs)
        GlobalManager.shared.unreadAnnouncementsCount = unreadAnnouncementsCount
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

    nonisolated static func == (lhs: AnnouncementListViewModel, rhs: AnnouncementListViewModel) -> Bool {
        return lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension MMKVHelper {
    enum Announcement {
        @MMKVStorage(key: "Announcement.readIDs", defaultValue: [])
        static var readIDs: [String]
    }
}
