//
//  RelativeDateStyle.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/28.
//

import Foundation
import SwiftUI

enum RelativeDateStyle {
    case secondary
    case overdue
    case today
    case tomorrow
    case dayAfterTomorrow
    case upcoming

    static func assignment(
        deadline: Date,
        isSubmitted: Bool = false,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Self {
        if isSubmitted {
            return .secondary
        }

        let timeRemaining = deadline.timeIntervalSince(now)
        let oneDay: TimeInterval = 24 * 60 * 60

        if timeRemaining < 0 {
            return .overdue
        }

        switch timeRemaining {
        case ..<oneDay:
            return .today
        case ..<(2 * oneDay):
            return .tomorrow
        case ..<(3 * oneDay):
            return .dayAfterTomorrow
        default:
            return .upcoming
        }
    }

    static func scheduled(
        for date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Self {
        switch dayOffset(from: now, to: date, calendar: calendar) {
        case ..<0:
            return .overdue
        case 0:
            return .today
        case 1:
            return .tomorrow
        case 2:
            return .dayAfterTomorrow
        default:
            return .upcoming
        }
    }

    var accentColor: Color {
        switch self {
        case .secondary:
            return .secondary
        case .overdue, .today:
            return .red
        case .tomorrow:
            return .orange
        case .dayAfterTomorrow:
            return .green
        case .upcoming:
            return .blue
        }
    }

    var badgeForegroundColor: Color {
        switch self {
        case .overdue, .today, .tomorrow:
            return .white
        case .secondary:
            return .secondary
        case .dayAfterTomorrow, .upcoming:
            return accentColor
        }
    }

    var badgeBackgroundColor: Color {
        switch self {
        case .overdue, .today, .tomorrow:
            return accentColor
        case .secondary:
            return Color.secondary.opacity(0.15)
        case .dayAfterTomorrow, .upcoming:
            return accentColor.opacity(0.14)
        }
    }

    var badgeBorderColor: Color {
        switch self {
        case .overdue, .today, .tomorrow:
            return .clear
        case .secondary:
            return Color.secondary.opacity(0.25)
        case .dayAfterTomorrow, .upcoming:
            return accentColor.opacity(0.22)
        }
    }

    var badgeBorderWidth: CGFloat {
        switch self {
        case .overdue, .today, .tomorrow:
            return 0
        case .secondary, .dayAfterTomorrow, .upcoming:
            return 0.5
        }
    }

    var cardBackgroundColor: Color {
        switch self {
        case .secondary:
            return Color.secondary.opacity(0.08)
        default:
            return accentColor.opacity(0.1)
        }
    }

    private static func dayOffset(from now: Date, to target: Date, calendar: Calendar) -> Int {
        let startOfToday = calendar.startOfDay(for: now)
        let targetDay = calendar.startOfDay(for: target)
        return calendar.dateComponents([.day], from: startOfToday, to: targetDay).day ?? 0
    }
}

struct RelativeDateBadge: View {
    let text: String
    let style: RelativeDateStyle
    var font: Font = .system(size: 12, weight: .bold)
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(style.badgeForegroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(style.badgeBackgroundColor, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(style.badgeBorderColor, lineWidth: style.badgeBorderWidth)
            }
    }
}
