//
//  SchoolCalendarListContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import SwiftUI

struct SchoolCalendarListContent: View {
    let schoolCalendars: [SchoolCalendar]

    let isLoadingCalendars: Bool

    @Binding var errorToast: ToastState

    let onQuery: () async -> Void

    // MARK: - Body

    var body: some View {
        ListPageScaffold(
            title: "校历列表",
            isEmpty: schoolCalendars.isEmpty,
            isLoading: isLoadingCalendars,
            emptyNoun: "校历",
            errorToast: $errorToast,
            onQuery: onQuery
        ) {
            ForEach(schoolCalendars) { calendar in
                CustomGroupBox {
                    NavigationLink(value: AppRoute.features(.campusTool(.schoolCalendarList(.detail(calendar))))) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(calendar.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(calendar.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right").frame(width: 16)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview("Normal") {
    NavigationStack {
        SchoolCalendarListContent(
            schoolCalendars: SchoolCalendarListPreviewData.calendars,
            isLoadingCalendars: false,
            errorToast: .constant(.errorTitle),
            onQuery: {}
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        SchoolCalendarListContent(
            schoolCalendars: [],
            isLoadingCalendars: false,
            errorToast: .constant(.errorTitle),
            onQuery: {}
        )
    }
}

// MARK: - Preview Data

private enum SchoolCalendarListPreviewData {
    static let calendars: [SchoolCalendar] = [
        SchoolCalendar(
            semesterCode: "2025-2026-2",
            title: "2025-2026学年第二学期",
            subtitle: "2026年2月23日 - 2026年7月12日"
        ),
        SchoolCalendar(
            semesterCode: "2025-2026-1",
            title: "2025-2026学年第一学期",
            subtitle: "2025年9月1日 - 2026年1月18日"
        ),
        SchoolCalendar(
            semesterCode: "2024-2025-2",
            title: "2024-2025学年第二学期",
            subtitle: "2025年2月24日 - 2025年7月13日"
        ),
    ]
}
