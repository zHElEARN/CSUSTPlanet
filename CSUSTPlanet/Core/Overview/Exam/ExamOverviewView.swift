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
    @Namespace var namespace
    @State private var refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000)

    var body: some View {
        let pendingExams = viewModel.pendingExams

        Group {
            #if os(macOS)
            TrackLink(destination: ExamScheduleView()) {
                CustomGroupBox {
                    cardContent(pendingExams: pendingExams)
                }
            }
            #elseif os(iOS)
            if #available(iOS 18.0, macOS 15.0, *) {
                TrackLink(
                    destination: ExamScheduleView()
                        .navigationTransition(.zoom(sourceID: "examSchedule", in: namespace))
                        .onDisappear { refreshID = Int(CFAbsoluteTimeGetCurrent() * 1000) }
                ) {
                    CustomGroupBox {
                        cardContent(pendingExams: pendingExams)
                            .matchedTransitionSource(id: "examSchedule", in: namespace)
                    }
                }
                .id(refreshID)
            } else {
                TrackLink(destination: ExamScheduleView()) {
                    CustomGroupBox {
                        cardContent(pendingExams: pendingExams)
                    }
                }
            }
            #endif
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func cardContent(pendingExams: [EduHelper.Exam]) -> some View {
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

    private var dateStyle: RelativeDateStyle {
        RelativeDateStyle.scheduled(for: exam.examStartTime)
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(dateStyle.accentColor)
                .frame(width: 4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exam.courseName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(locationText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)

                VStack(alignment: .trailing, spacing: 4) {
                    RelativeDateBadge(
                        text: statusText,
                        style: dateStyle
                    )

                    Text(timeRangeText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(dateStyle.cardBackgroundColor)
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

    private var locationText: String {
        exam.examRoom.isEmpty ? "地点待定" : exam.examRoom
    }

    private var timeRangeText: String {
        let start = exam.examStartTime.formatted(.dateTime.month().day().hour().minute())
        let end = exam.examEndTime.formatted(.dateTime.hour().minute())
        return "\(start)-\(end)"
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
