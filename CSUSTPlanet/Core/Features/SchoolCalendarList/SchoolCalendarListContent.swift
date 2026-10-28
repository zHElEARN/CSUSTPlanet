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
