//
//  OverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewView: View {
    @State var viewModel = OverviewViewModel()
    @Bindable var globalManager = GlobalManager.shared

    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部欢迎语
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(Date().formatted(.dateTime.month().day().weekday()))
                        if let weekInfo = viewModel.weekInfo {
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

                // 今日课程
                CourseOverviewView(viewModel: viewModel)

                // 核心数据网格 (成绩 + 电量)
                HStack(spacing: 16) {
                    GradeOverviewView(viewModel: viewModel)
                    DormOverviewView(viewModel: viewModel)
                }
                .padding(.horizontal)

                // 作业与考试
                let columns = sizeClass == .regular ? [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)] : [GridItem(.flexible(), spacing: 24)]

                LazyVGrid(columns: columns, spacing: 24) {
                    // 待提交作业
                    AssignmentOverviewView(viewModel: viewModel)

                    // 考试安排
                    ExamOverviewView(viewModel: viewModel)
                }
                .padding(.horizontal)

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("概览")
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .onAppear(perform: viewModel.onAppear)
        .navigationDestination(isPresented: $globalManager.isFromElectricityWidget) {
            ElectricityQueryView().trackRoot("Widget")
        }
        .navigationDestination(isPresented: $globalManager.isFromCourseScheduleWidget) {
            CourseScheduleView().trackRoot("Widget")
        }
        .navigationDestination(isPresented: $globalManager.isFromGradeAnalysisWidget) {
            GradeAnalysisView().trackRoot("Widget")
        }
        .navigationDestination(isPresented: $globalManager.isFromUrgentCoursesWidget) {
            TodoAssignmentsView().trackRoot("Widget")
        }
        .trackView("Overview")
    }
}
