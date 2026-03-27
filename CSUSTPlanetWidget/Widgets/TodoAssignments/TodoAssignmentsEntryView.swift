//
//  TodoAssignmentsEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import SwiftUI
import WidgetKit

struct TodoAssignmentsEntryView: View {
    @Environment(\.widgetFamily) private var family

    var entry: TodoAssignmentsProvider.Entry

    var body: some View {
        Group {
            if let data = entry.data, let lastUpdated = entry.lastUpdated {
                contentView(data: data, lastUpdated: lastUpdated)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .topTrailing) {
                    emptyView.frame(maxWidth: .infinity, maxHeight: .infinity)
                    refreshButtonView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "csustplanet://widgets/todoAssignments"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    @ViewBuilder
    private func contentView(data: [TodoAssignmentsData], lastUpdated: Date) -> some View {
        let summary = displaySummary(from: data)

        VStack(spacing: 0) {
            headerView(summary: summary, lastUpdated: lastUpdated)
            Divider().padding(.vertical, 4)

            if summary.totalAssignments == 0 {
                emptyAssignmentsView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { proxy in
                    let rowHeight = rowHeight(for: proxy.size.height, rowCount: maxContentRows)

                    VStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(summary.contentItems, id: \.assignment.id) { item in
                            assignmentRowView(item: item)
                                .frame(height: rowHeight, alignment: .leading)
                        }

                        if summary.showsOverflowInContent {
                            overflowRowView(remainingAssignments: summary.remainingAssignments)
                                .frame(height: rowHeight, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            footerView(lastUpdated: lastUpdated)
        }
    }

    private func displaySummary(from data: [TodoAssignmentsData]) -> DisplaySummary {
        let referenceDate = Date.now
        let items =
            data
            .flatMap { group in
                group.assignments
                    .filter { $0.deadline >= referenceDate }
                    .map { DisplayAssignmentItem(courseName: group.course.name, assignment: $0) }
            }
            .sorted { $0.assignment.deadline < $1.assignment.deadline }

        let maxContentRows = self.maxContentRows
        let showsOverflowInHeader = family == .systemMedium && items.count > maxContentRows
        let showsOverflowInContent = family == .systemSmall && items.count > maxContentRows
        let maxVisibleAssignments = showsOverflowInContent ? maxContentRows - 1 : maxContentRows
        let displayedItems = Array(items.prefix(maxVisibleAssignments))

        return DisplaySummary(
            contentItems: displayedItems,
            totalAssignments: items.count,
            remainingAssignments: max(0, items.count - displayedItems.count),
            showsOverflowInHeader: showsOverflowInHeader,
            showsOverflowInContent: showsOverflowInContent
        )
    }

    @ViewBuilder
    private func headerView(summary: DisplaySummary, lastUpdated: Date) -> some View {
        HStack(alignment: .center, spacing: 4) {
            Text("待提交作业")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)

            Text("\(summary.totalAssignments)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.red)

            if family == .systemMedium {
                lastUpdatedDateView(lastUpdated: lastUpdated)
            }

            Spacer()

            if summary.showsOverflowInHeader {
                Text("还有 \(summary.remainingAssignments) 个")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            refreshButtonView
        }
    }

    @ViewBuilder
    private func assignmentRowView(item: DisplayAssignmentItem) -> some View {
        HStack(alignment: .center, spacing: 0) {
            if family == .systemMedium {
                HStack(alignment: .center, spacing: 2) {
                    Text(item.assignment.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .layoutPriority(1)

                    Text(item.courseName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(item.assignment.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            deadlineBadge(for: item.assignment)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func deadlineBadge(for assignment: MoocHelper.Assignment) -> some View {
        Text(assignment.deadline, format: .relative(presentation: .named, unitsStyle: .abbreviated))
            .font(.caption2)
            .foregroundStyle(badgeForegroundColor(for: assignment))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeForegroundColor(for: assignment).opacity(0.15), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(badgeForegroundColor(for: assignment).opacity(0.22), lineWidth: 0.5)
            }
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private func overflowRowView(remainingAssignments: Int) -> some View {
        Text("还有 \(remainingAssignments) 个作业未展示")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))

            VStack(spacing: 4) {
                Text("暂无作业数据")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("请点击右上角刷新按钮尝试刷新作业数据")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var emptyAssignmentsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: family == .systemMedium ? 22 : 18))
                .foregroundStyle(.green)

            Text("暂无未截止作业")
                .font(.system(size: family == .systemMedium ? 14 : 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    var refreshButtonView: some View {
        Button(intent: RefreshTodoAssignmentsTimelineIntent()) {
            Image(systemName: "arrow.clockwise.circle")
        }
        .foregroundStyle(.blue)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func footerView(lastUpdated: Date) -> some View {
        if family == .systemSmall {
            lastUpdatedDateView(lastUpdated: lastUpdated)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func lastUpdatedDateView(lastUpdated: Date) -> some View {
        Text("更新于：")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            + Text(lastUpdated, style: .relative)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            + Text("前")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private var rowSpacing: CGFloat {
        family == .systemMedium ? 4 : 3
    }

    private var maxContentRows: Int {
        family == .systemSmall ? 4 : 5
    }

    private func rowHeight(for availableHeight: CGFloat, rowCount: Int) -> CGFloat {
        guard rowCount > 0 else { return 0 }

        let totalSpacing = rowSpacing * CGFloat(max(0, rowCount - 1))
        return max(0, (availableHeight - totalSpacing) / CGFloat(rowCount))
    }

    private func badgeForegroundColor(for assignment: MoocHelper.Assignment) -> Color {
        if assignment.submitStatus {
            return .secondary
        }

        let timeRemaining = assignment.deadline.timeIntervalSinceNow
        if timeRemaining <= 12 * 3600 {
            return .red
        }

        if assignment.canSubmit {
            return .orange
        }

        return .secondary
    }
}

private struct DisplaySummary {
    let contentItems: [DisplayAssignmentItem]
    let totalAssignments: Int
    let remainingAssignments: Int
    let showsOverflowInHeader: Bool
    let showsOverflowInContent: Bool
}

private struct DisplayAssignmentItem {
    let courseName: String
    let assignment: MoocHelper.Assignment
}
