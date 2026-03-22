//
//  AssignmentOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct AssignmentOverviewView: View {
    @Bindable var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            OverviewSectionHeader(
                title: "待提交作业",
                icon: "doc.text.fill",
                color: .red,
                destination: TodoAssignmentsView()
            )

            let assignments = viewModel.submittableAssignments
            if assignments.isEmpty {
                OverviewEmptyStateView(icon: "doc.text", text: "暂无待提交作业")
            } else {
                AssignmentListView(assignments: assignments)
            }
        }
    }
}

private struct AssignmentListView: View {
    let assignments: [(courseName: String, assignment: MoocHelper.Assignment)]

    var body: some View {
        TrackLink(destination: TodoAssignmentsView()) {
            VStack(spacing: 0) {
                ForEach(assignments.indices, id: \.self) { index in
                    let item = assignments[index]

                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.orange)
                            .frame(width: 4, height: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.assignment.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text(item.courseName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("截止时间")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(item.assignment.deadline, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(12)

                    if index < assignments.count - 1 {
                        Divider().padding(.leading, 28)
                    }
                }
            }
            #if os(iOS)
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            #else
            .background(Color(PlatformColor.controlBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
