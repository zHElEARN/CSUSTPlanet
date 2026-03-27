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

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                OverviewHeaderView()

                CourseOverviewView()

                VStack(spacing: 24) {
                    GradeOverviewView()

                    DormOverviewView()

                    AssignmentOverviewView()

                    ExamOverviewView()
                }
                .padding(.horizontal)

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
}
