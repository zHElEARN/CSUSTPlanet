//
//  OverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewView: View {
    @Bindable var globalManager = GlobalManager.shared

    private let overviewSpacing: CGFloat = 24
    private let minimumColumnWidth: CGFloat = 320

    private var overviewSubtitle: String {
        let dateText = Date().formatted(.dateTime.month().day().weekday())

        guard let weekInfo else {
            return dateText
        }

        return "\(dateText) · \(weekInfo)"
    }

    private var weekInfo: String? {
        guard let data = MMKVHelper.shared.courseScheduleCache?.value else {
            return nil
        }

        let semester = data.semester ?? "默认学期"

        if let currentWeek = CourseScheduleUtil.getCurrentWeek(
            semesterStartDate: data.semesterStartDate,
            now: .now
        ) {
            return "\(semester) 第\(currentWeek)周"
        }

        return semester
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                legacyOverviewHeader

                responsiveOverviewContent

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("概览")
        .navigationSubtitleCompat(overviewSubtitle)
        .navigationDestination(isPresented: $globalManager.isFromElectricityWidget) {
            DormListView().trackRoot("Widget")
        }
        .navigationDestination(isPresented: $globalManager.isFromCourseScheduleWidget) {
            CourseScheduleView().trackRoot("Widget")
        }
        .navigationDestination(isPresented: $globalManager.isFromGradeAnalysisWidget) {
            GradeAnalysisView().trackRoot("Widget")
        }
        .navigationDestination(isPresented: $globalManager.isFromTodoAssignmentsWidget) {
            TodoAssignmentsView().trackRoot("Widget")
        }
        .trackView("Overview")
    }

    @ViewBuilder
    private var responsiveOverviewContent: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: overviewSpacing) {
                overviewColumn {
                    CourseOverviewView()
                    GradeOverviewView()
                    DormOverviewView()
                }
                .frame(minWidth: minimumColumnWidth, maxWidth: .infinity, alignment: .top)
                .fixedSize(horizontal: false, vertical: true)

                overviewColumn {
                    AssignmentOverviewView()
                    ExamOverviewView()
                }
                .frame(minWidth: minimumColumnWidth, maxWidth: .infinity, alignment: .top)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)

            overviewColumn {
                CourseOverviewView()
                GradeOverviewView()
                DormOverviewView()
                AssignmentOverviewView()
                ExamOverviewView()
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var legacyOverviewHeader: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(Date().formatted(.dateTime.month().day().weekday()))

                    if let weekInfo {
                        Text("·")
                        Text(weekInfo)
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 10)
        }
    }

    private func overviewColumn<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: overviewSpacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
