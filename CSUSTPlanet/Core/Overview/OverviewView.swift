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

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OverviewHeaderView()

                responsiveOverviewContent

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("概览")
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

                overviewColumn {
                    AssignmentOverviewView()
                    ExamOverviewView()
                }
                .frame(minWidth: minimumColumnWidth, maxWidth: .infinity, alignment: .top)
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

    private func overviewColumn<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: overviewSpacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
