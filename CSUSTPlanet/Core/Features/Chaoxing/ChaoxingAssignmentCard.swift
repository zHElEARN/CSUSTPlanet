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

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #else
    @State private var isWebPagePresented = false
    #endif

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
                    openDetail(detailURL)
                } label: {
                    cardContent
                }
                .buttonStyle(.plain)
                .contentShape(.rect)
            } else {
                cardContent
            }
        }
        #if os(iOS)
        .sheet(isPresented: $isWebPagePresented) {
            if let detailURL {
                NavigationStack {
                    ChaoxingAssignmentDetailView(detailURL: detailURL)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                isWebPagePresented = false
                            }
                        }
                    }
                }
            }
        }
        #endif
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
                    statusView
                    deadlineView
                }
            }
        }
    }

    private func openDetail(_ url: URL) {
        #if os(macOS)
        openWindow(id: ChaoxingAssignmentDetailScene.windowID, value: url)
        #else
        isWebPagePresented = true
        #endif
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

    @ViewBuilder
    private var statusView: some View {
        if assignment.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundColor(.green)
        } else {
            Image(systemName: "circle")
                .font(.footnote)
                .foregroundColor(.orange)
        }
    }
}

#Preview("ChaoxingAssignmentCard") {
    CustomScrollView {
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[0])
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[1])
        ChaoxingAssignmentCard(assignment: ChaoxingAssignmentsPreviewData.assignments[2])
    }
    .padding()
}
