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
        let pendingExams = viewModel.pendingExams

        TrackLink(destination: ExamScheduleView()) {
            CustomGroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    Text("考试安排")
                        .font(.title3)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)

                    if pendingExams.isEmpty {
                        EmptyExamContentView()
                    } else {
                        ExamListView(
                            pendingExams: pendingExams,
                            daysUntilExam: viewModel.daysUntilExam
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .onAppear(perform: viewModel.onAppear)
    }
}

private struct ExamListView: View {
    let pendingExams: [EduHelper.Exam]
    let daysUntilExam: (EduHelper.Exam) -> Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(pendingExams.enumerated()), id: \.offset) { _, exam in
                ExamRowView(exam: exam, daysUntilExam: daysUntilExam(exam))
            }
        }
    }
}

private struct ExamRowView: View {
    let exam: EduHelper.Exam
    let daysUntilExam: Int

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 4)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exam.courseName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(exam.examTime)
                            .lineLimit(1)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                    if !exam.examRoom.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "building.columns.fill")
                                .font(.caption)
                            Text(exam.examRoom)
                                .lineLimit(1)
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(statusText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(statusForegroundColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusBackgroundColor, in: Capsule())

                    Text(exam.examStartTime, format: .dateTime.month().day().weekday(.abbreviated))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(statusColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var statusText: String {
        switch daysUntilExam {
        case 0:
            return "今天"
        case 1:
            return "明天"
        case 2:
            return "后天"
        default:
            return "还有 \(daysUntilExam) 天"
        }
    }

    private var statusColor: Color {
        switch daysUntilExam {
        case 0:
            return .red
        case 1:
            return .orange
        case 2:
            return .green
        default:
            return .blue
        }
    }

    private var statusForegroundColor: Color {
        switch daysUntilExam {
        case 0, 1:
            return .white
        default:
            return statusColor
        }
    }

    private var statusBackgroundColor: Color {
        switch daysUntilExam {
        case 0, 1:
            return statusColor
        default:
            return statusColor.opacity(0.14)
        }
    }
}

private struct EmptyExamContentView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title3)
                .foregroundStyle(.green)

            Text("暂无考试安排")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
