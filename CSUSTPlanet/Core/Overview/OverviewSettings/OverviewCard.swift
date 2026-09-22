//
//  OverviewCard.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/23.
//

import Foundation

enum OverviewCard: String, CaseIterable {
    case course
    case grade
    case dorm
    case assignment
    case exam
    case announcement

    var title: String {
        switch self {
        case .course: return "我的课表"
        case .grade: return "成绩查询"
        case .dorm: return "宿舍电量"
        case .assignment: return "待提交作业"
        case .exam: return "考试安排"
        case .announcement: return "App公告"
        }
    }

    var systemImage: String {
        switch self {
        case .course: return "calendar"
        case .grade: return "doc.text.magnifyingglass"
        case .dorm: return "bolt.fill"
        case .assignment: return "list.bullet.clipboard"
        case .exam: return "pencil.and.outline"
        case .announcement: return "megaphone"
        }
    }

    static func sanitized(_ ids: [String]) -> [OverviewCard] {
        let stored = ids.compactMap(OverviewCard.init(rawValue:))
        let missing = allCases.filter { !stored.contains($0) }
        return stored + missing
    }
}

extension MMKVHelper {
    enum OverviewSettings {
        @MMKVStorage(key: "OverviewSettings.isAutoSortEnabled", defaultValue: true)
        static var isAutoSortEnabled: Bool

        @MMKVStorage(key: "OverviewSettings.cardOrder", defaultValue: OverviewCard.allCases.map(\.rawValue))
        static var cardOrder: [String]

        static var orderedCards: [OverviewCard] {
            get { OverviewCard.sanitized(cardOrder) }
            set { cardOrder = newValue.map(\.rawValue) }
        }
    }
}
