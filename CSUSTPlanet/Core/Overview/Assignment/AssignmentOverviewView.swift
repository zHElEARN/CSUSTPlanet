//
//  AssignmentOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct AssignmentOverviewView: View {
    @State private var viewModel = AssignmentOverviewViewModel()

    var body: some View {
        let assignments = viewModel.submittableAssignments

        TrackLink(destination: TodoAssignmentsView()) {
            CustomGroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Text("待提交作业")
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)

                    if assignments.isEmpty {
                        EmptyAssignmentContentView()
                    } else {
                        AssignmentListView(assignments: assignments)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .onAppear(perform: viewModel.onAppear)
    }
}

private struct AssignmentListView: View {
    let assignments: [(courseName: String, assignment: MoocHelper.Assignment)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(assignments.indices, id: \.self) { index in
                AssignmentRowView(item: assignments[index])
            }
        }
    }
}

private struct AssignmentRowView: View {
    let item: (courseName: String, assignment: MoocHelper.Assignment)

    private var deadlineStyle: RelativeDateStyle {
        RelativeDateStyle.assignment(deadline: item.assignment.deadline)
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(deadlineStyle.accentColor)
                .frame(width: 4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.assignment.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(item.courseName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)

                VStack(alignment: .trailing, spacing: 4) {
                    RelativeDateBadge(
                        text: item.assignment.deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                        style: deadlineStyle
                    )
                    .lineLimit(1)

                    Text(item.assignment.deadline, format: .dateTime.month().day().hour().minute())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.trailing, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(deadlineStyle.cardBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

private struct EmptyAssignmentContentView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)

            Text("暂无待提交作业")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
