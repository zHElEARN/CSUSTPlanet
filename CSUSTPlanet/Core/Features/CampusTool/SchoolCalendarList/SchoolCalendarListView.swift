//
//  SchoolCalendarListView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import AlertToast
import SwiftUI

struct SchoolCalendarListView: View {
    @State var viewModel = SchoolCalendarListViewModel()

    var body: some View {
        ListPageScaffold(
            title: "校历列表",
            isEmpty: viewModel.schoolCalendars.isEmpty,
            isLoading: viewModel.isLoadingCalendars,
            emptyNoun: "校历",
            errorToast: $viewModel.errorToast,
            onQuery: viewModel.loadSchoolCalendars
        ) {
            ForEach(viewModel.schoolCalendars) { calendar in
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
        .task { await viewModel.loadSchoolCalendars() }
    }
}
