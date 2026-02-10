//
//  ExamOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct ExamOverviewView: View {
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            HomeSectionHeader(
                title: "考试安排",
                icon: "calendar.badge.clock",
                color: .orange,
                destination: ExamScheduleView()
            )

            let pendingExams = viewModel.pendingExams
            if pendingExams.isEmpty {
                if viewModel.examScheduleData?.value == nil {
                    HomeEmptyStateView(icon: "calendar.badge.exclamationmark", text: "暂无数据，请前往详情页加载")
                } else {
                    HomeEmptyStateView(icon: "calendar.badge.checkmark", text: "近期没有考试")
                }
            } else {
                ExamListView(viewModel: viewModel)
            }
        }
    }
}

private struct ExamListView: View {
    @ObservedObject var viewModel: OverviewViewModel

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.displayedExams, id: \.courseName) { exam in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exam.courseName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            Text(exam.examTime)
                            if !exam.examRoom.isEmpty {
                                Text("·")
                                Text(exam.examRoom)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }

                    Spacer()

                    let daysLeft = viewModel.daysUntilExam(exam)
                    if daysLeft == 0 {
                        Text("今天")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red, in: Capsule())
                    } else if daysLeft == 1 {
                        Text("明天")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange, in: Capsule())
                    } else {
                        Text("还有 \(daysLeft) 天")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1), in: Capsule())
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if viewModel.examsRemainingCount > 0 {
                TrackLink(destination: ExamScheduleView()) {
                    Text("还有 \(viewModel.examsRemainingCount) 场考试安排...")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
    }
}
