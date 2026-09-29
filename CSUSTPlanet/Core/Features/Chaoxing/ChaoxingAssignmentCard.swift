//
//  ChaoxingAssignmentCard.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import CSUSTKit
import Kingfisher
import SwiftUI

struct ChaoxingAssignmentCard: View {
    let assignment: ChaoxingHelper.Assignment

    let onRequestOpen: (URL) -> Void

    private var detailURL: URL? {
        URL(string: assignment.detailURL)
    }

    private var deadlineStyle: RelativeDateStyle? {
        assignment.deadline.map {
            RelativeDateStyle.assignment(deadline: $0, isSubmitted: assignment.isCompleted)
        }
    }

    var body: some View {
        Group {
            if let detailURL {
                Button {
                    onRequestOpen(detailURL)
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
                .contentShape(.rect)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        CustomGroupBox {
            HStack(alignment: .top, spacing: 12) {
                iconView

                VStack(alignment: .leading, spacing: 6) {
                    Text(assignment.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(assignment.courseName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    statusBadge
                    deadlineView
                }
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconURL = URL(string: assignment.iconURL) {
            let resource = KF.ImageResource(
                downloadURL: iconURL,
                cacheKey: iconURL.absoluteString.components(separatedBy: "?").first ?? assignment.iconURL
            )

            KFImage(source: .network(resource))
                .placeholder {
                    ProgressView().smallControlSizeOnMac()
                }
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "list.bullet.clipboard")
                        .foregroundStyle(.secondary)
                }
        }
    }

    @ViewBuilder
    private var deadlineView: some View {
        if let deadline = assignment.deadline, let style = deadlineStyle {
            HStack(spacing: 6) {
                Text(deadline, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(style.accentColor)

                RelativeDateBadge(
                    text: deadline.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)),
                    style: style,
                    font: .caption2.bold(),
                    horizontalPadding: 6,
                    verticalPadding: 2
                )
            }
        } else {
            Text("无截止时间")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// 作业状态，原样展示学习通返回的文本，统一使用中性色，不做状态配色
    private var statusBadge: some View {
        RelativeDateBadge(
            text: assignment.status,
            style: .secondary,
            font: .caption2.bold(),
            horizontalPadding: 6,
            verticalPadding: 2
        )
    }
}

#Preview("ChaoxingAssignmentCard") {
    CustomScrollView {
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[0], onRequestOpen: { _ in })
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[1], onRequestOpen: { _ in })
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[2], onRequestOpen: { _ in })
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[3], onRequestOpen: { _ in })
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[4], onRequestOpen: { _ in })
    }
    .padding()
}
