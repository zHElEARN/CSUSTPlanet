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
    @State private var courseScheduleData = MMKVHelper.shared.courseScheduleCache

    private let overviewSpacing: CGFloat = 24
    private let minimumColumnWidth: CGFloat = 320

    private var overviewSubtitle: String {
        let dateText = Date().formatted(.dateTime.month().day().weekday())
        var components: [String] = []

        components.append(dateText)

        if let currentWeekText {
            components.append(currentWeekText)
        }

        return components.joined(separator: " ")
    }

    private var currentWeekText: String? {
        guard let data = courseScheduleData?.value else {
            return nil
        }

        if let currentWeek = CourseScheduleUtil.getCurrentWeek(
            semesterStartDate: data.semesterStartDate,
            now: .now
        ) {
            return "第\(currentWeek)周"
        }

        return nil
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
        .onReceive(MMKVHelper.shared.$courseScheduleCache) { data in
            courseScheduleData = data
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
                    AnnouncementOverviewView()
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
                AnnouncementOverviewView()
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
                Text(overviewSubtitle)
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
