//
//  CoursesContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/21.
//

import CSUSTKit
import SwiftUI

struct CoursesContent: View {
    let courses: [MoocHelper.Course]

    @State private var searchText = ""

    let isLoading: Bool

    @Binding var errorToast: ToastState

    let onRefreshCourses: () async -> Void

    private var filteredCourses: [MoocHelper.Course] {
        guard !searchText.isEmpty else {
            return courses
        }

        return courses.filter { course in
            course.name.localizedCaseInsensitiveContains(searchText)
                || course.teacher?.localizedCaseInsensitiveContains(searchText) == true
                || course.department?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        ListPageScaffold(
            title: "课程列表",
            subtitle: "共\(courses.count)门课程",
            isEmpty: filteredCourses.isEmpty,
            isLoading: isLoading,
            emptyNoun: "课程",
            searchText: $searchText,
            errorToast: $errorToast,
            onQuery: onRefreshCourses
        ) {
            ForEach(filteredCourses, id: \.id) { course in
                CustomGroupBox {
                    NavigationLink(value: AppRoute.features(.mooc(.courses(.detail(course))))) {
                        courseRow(course)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func courseRow(_ course: MoocHelper.Course) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(course.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let teacher = course.teacher, let department = course.department {
                    HStack(spacing: 12) {
                        infoItem(icon: "person.fill", color: .purple, text: teacher)
                        infoItem(icon: "building.columns.fill", color: .green, text: department)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .frame(width: 16)
        }
        .padding(.vertical, 6)
    }

    private func infoItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
