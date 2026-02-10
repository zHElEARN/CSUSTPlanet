//
//  AssignmentOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct AssignmentOverviewView: View {
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            HomeSectionHeader(
                title: "待提交作业",
                icon: "doc.text.fill",
                color: .red,
                destination: UrgentCoursesView()
            )

            let courses = viewModel.urgentCourses
            if courses.isEmpty {
                if viewModel.urgentCoursesData?.value == nil {
                    HomeEmptyStateView(icon: "doc.text", text: "暂无数据，请前往详情页加载")
                } else {
                    HomeEmptyStateView(icon: "doc.text", text: "暂无待提交作业")
                }
            } else {
                AssignmentListView(viewModel: viewModel)
            }
        }
    }
}

private struct AssignmentListView: View {
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.displayedUrgentCourses, id: \.name) { course in
                TrackLink(destination: UrgentCoursesView()) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange)
                            .frame(width: 4, height: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Text("待提交")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if viewModel.urgentCoursesRemainingCount > 0 {
                TrackLink(destination: UrgentCoursesView()) {
                    Text("还有 \(viewModel.urgentCoursesRemainingCount) 项作业待提交...")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }
}
