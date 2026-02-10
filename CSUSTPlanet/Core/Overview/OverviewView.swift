//
//  OverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct OverviewView: View {
    @StateObject var viewModel = OverviewViewModel()
    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var globalManager: GlobalManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 头部欢迎语
                    HomeHeaderView(weekInfo: viewModel.weekInfo)
                        .padding(.horizontal)
                        .padding(.top, 10)

                    // 今日课程
                    CourseOverviewView(viewModel: viewModel)

                    // 核心数据网格 (成绩 + 电量)
                    HStack(spacing: 16) {
                        GradeOverviewView(analysisData: viewModel.currentGradeAnalysis)
                        DormOverviewView(primaryDorm: viewModel.primaryDorm, exhaustionInfo: viewModel.electricityExhaustionInfo)
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
                .frame(maxWidth: sizeClass == .regular ? 900 : .infinity)
                .frame(maxWidth: .infinity)
                .padding(.top, sizeClass == .regular ? 20 : 0)
            }
            .navigationTitle("概览")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                viewModel.loadData()
            }
            .navigationDestination(isPresented: $globalManager.isFromElectricityWidget) {
                ElectricityQueryView()
                    .trackRoot("Widget")
            }
            .navigationDestination(isPresented: $globalManager.isFromCourseScheduleWidget) {
                CourseScheduleView()
                    .trackRoot("Widget")
            }
            .navigationDestination(isPresented: $globalManager.isFromGradeAnalysisWidget) {
                GradeAnalysisView()
                    .trackRoot("Widget")
            }
            .navigationDestination(isPresented: $globalManager.isFromUrgentCoursesWidget) {
                UrgentCoursesView()
                    .trackRoot("Widget")
            }
            .trackView("Overview")
        }
        .tabItem {
            Image(uiImage: UIImage(systemName: "rectangle.stack")!)
            Text("概览")
        }
    }
}

#Preview {
    OverviewView()
}
