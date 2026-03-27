//
//  ExamOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct ExamOverviewView: View {
    @State private var viewModel = ExamOverviewViewModel()

    var body: some View {
        VStack(spacing: 12) {
            OverviewSectionHeader(
                title: "考试安排",
                icon: "calendar.badge.clock",
                color: .orange,
                destination: ExamScheduleView()
            )

            let pendingExams = viewModel.pendingExams
            if pendingExams.isEmpty {
                OverviewEmptyStateView(icon: "calendar.badge.checkmark", text: "暂无考试安排")
            } else {
                ExamListView(
                    pendingExams: pendingExams,
                    daysUntilExam: viewModel.daysUntilExam
                )
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }
}

private struct ExamListView: View {
    let pendingExams: [EduHelper.Exam]
    let daysUntilExam: (EduHelper.Exam) -> Int

    var body: some View {
        CustomGroupBox {
            VStack(spacing: 0) {
                ForEach(Array(pendingExams.enumerated()), id: \.offset) { index, exam in
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

                        let daysLeft = daysUntilExam(exam)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)

                    if index < pendingExams.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}
