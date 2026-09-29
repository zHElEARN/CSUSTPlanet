//
//  ChaoxingAssignmentsOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import CSUSTKit
import SwiftUI

struct ChaoxingAssignmentsOverviewView: View {
    @State private var cache: Cached<[ChaoxingHelper.Assignment]>?
    @State private var isFirstObservation = true
    @State private var isLoading = false

    @Environment(Router.self) private var router

    /// 未提交作业按截止时间升序排在前面，无截止时间排在最后
    private var uncompletedAssignments: [ChaoxingHelper.Assignment] {
        (cache?.value ?? [])
            .filter { !$0.isCompleted }
            .enumerated()
            .sorted { lhs, rhs in
                let lhsDeadline = lhs.element.deadline
                let rhsDeadline = rhs.element.deadline

                if let lhsDeadline, let rhsDeadline, lhsDeadline != rhsDeadline {
                    return lhsDeadline < rhsDeadline
                }
                if lhsDeadline == nil, rhsDeadline != nil {
                    return false
                }
                if lhsDeadline != nil, rhsDeadline == nil {
                    return true
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    var body: some View {
        Button(action: { router.deepLinkTo(feature: .chaoxingAssignments) }) {
            CustomGroupBox {
                cardContent
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onReceive(MMKVHelper.ChaoxingAssignments.$cache.receive(on: DispatchQueue.main)) { data in
            if isFirstObservation {
                cache = data
                isFirstObservation = false
            } else {
                withAnimation {
                    cache = data
                }
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("学习通作业")
                    .font(.title3)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)

                Spacer()

                if let lastUpdated = cache?.cachedAt {
                    LastUpdatedDateView(
                        lastUpdated: lastUpdated,
                        font: .footnote,
                        foregroundStyle: .secondary
                    )
                    .contentTransition(.numericText())
                }

                Button(asyncAction: loadAssignments) {
                    Image(systemName: "arrow.clockwise.circle")
                }
                .disabled(isLoading)
            }

            if uncompletedAssignments.isEmpty {
                Text("暂无作业")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .redacted(reason: isLoading ? .placeholder : [])
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(uncompletedAssignments, id: \.self) { assignment in
                        ChaoxingAssignmentOverviewRow(assignment: assignment)
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadAssignments() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedAssignments = try await AuthManager.shared.withAuthRetry(system: .chaoxing) {
                try await AuthManager.shared.chaoxingHelper.getAssignments()
            }
            MMKVHelper.ChaoxingAssignments.cache = Cached(cachedAt: .now, value: fetchedAssignments)
        } catch {
            // [INFO] 暂时不处理错误
        }
    }
}

private struct ChaoxingAssignmentOverviewRow: View {
    let assignment: ChaoxingHelper.Assignment

    private var deadlineStyle: RelativeDateStyle {
        assignment.deadline.map { RelativeDateStyle.assignment(deadline: $0) } ?? .secondary
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(deadlineStyle.accentColor)
                .frame(width: 4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(assignment.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(assignment.courseName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)

                VStack(alignment: .trailing, spacing: 4) {
                    if let deadline = assignment.deadline {
                        RelativeDateBadge(
                            text: deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                            style: deadlineStyle
                        )
                        .lineLimit(1)

                        Text(deadline, format: .dateTime.month().day().hour().minute())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    } else {
                        Text("无截止时间")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
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
