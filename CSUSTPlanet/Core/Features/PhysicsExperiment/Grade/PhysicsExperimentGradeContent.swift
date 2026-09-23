//
//  PhysicsExperimentGradeContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/23.
//

import CSUSTKit
import SwiftUI

struct PhysicsExperimentGradeContent: View {
    let grades: [PhysicsExperimentHelper.CourseGrade]?

    let isLoadingGrades: Bool

    @Binding var isLoginPresented: Bool
    @Binding var errorToast: ToastState

    let onRefreshGrades: () async -> Void

    var body: some View {
        Group {
            if let grades, !grades.isEmpty {
                CustomScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(grades, id: \.itemName) { grade in
                            GradeCardView(grade: grade)
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "暂无成绩信息",
                    systemImage: "chart.bar.doc.horizontal",
                    description: Text("没有找到任何大物实验成绩信息")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .errorToast($errorToast)
        .sheet(isPresented: $isLoginPresented) {
            PhysicsExperimentLoginView()
        }
        .safeRefreshable { await onRefreshGrades() }
        .navigationTitle("大物实验成绩")
        .navigationSubtitleCompat("共\(grades?.count ?? 0)项成绩")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { isLoginPresented = true }) {
                    Text("登录")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefreshGrades) {
                    if isLoadingGrades {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoadingGrades)
            }
        }
    }
}

struct GradeCardView: View {
    let grade: PhysicsExperimentHelper.CourseGrade

    var body: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 10) {
                // 项目名称
                Text(grade.itemName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                // 成绩详情
                VStack(spacing: 6) {
                    HStack {
                        // 预习成绩
                        gradeItem(label: "预习", score: grade.previewGrade, color: .purple)
                        Spacer()
                        // 操作成绩
                        gradeItem(label: "操作", score: grade.operationGrade, color: .blue)
                        Spacer()
                        // 报告成绩
                        gradeItem(label: "报告", score: grade.reportGrade, color: .green)
                    }

                    // 总成绩
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .imageScale(.small)
                            Text("总成绩")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Text("\(grade.totalGrade)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(ColorUtil.dynamicColor(grade: Double(grade.totalGrade)))
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func gradeItem(label: String, score: Int?, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let score = score {
                Text("\(score)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            } else {
                Text("-")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("PhysicsExperimentGradeContent") {
    @Previewable @State var isLoginPresented = false
    @Previewable @State var errorToast = ToastState.errorTitle

    NavigationStack {
        PhysicsExperimentGradeContent(
            grades: PhysicsExperimentGradePreviewData.grades,
            isLoadingGrades: false,
            isLoginPresented: $isLoginPresented,
            errorToast: $errorToast,
            onRefreshGrades: {}
        )
    }
}

#Preview("PhysicsExperimentGradeContent Empty") {
    @Previewable @State var isLoginPresented = false
    @Previewable @State var errorToast = ToastState.errorTitle

    NavigationStack {
        PhysicsExperimentGradeContent(
            grades: [],
            isLoadingGrades: false,
            isLoginPresented: $isLoginPresented,
            errorToast: $errorToast,
            onRefreshGrades: {}
        )
    }
}

// MARK: - Preview Data

private enum PhysicsExperimentGradePreviewData {
    static let grades: [PhysicsExperimentHelper.CourseGrade] = [
        makeGrade("PHYS1001", "大学物理实验", "用示波器观测周期性电信号", 92, 88, 95, 91),
        makeGrade("PHYS1001", "大学物理实验", "分光计的调节与使用", 85, 90, nil, 87),
        makeGrade("PHYS1001", "大学物理实验", "光电效应测普朗克常数", nil, nil, nil, 78),
    ]

    private static func makeGrade(
        _ courseCode: String,
        _ courseName: String,
        _ itemName: String,
        _ previewGrade: Int?,
        _ operationGrade: Int?,
        _ reportGrade: Int?,
        _ totalGrade: Int
    ) -> PhysicsExperimentHelper.CourseGrade {
        PhysicsExperimentHelper.CourseGrade(
            courseCode: courseCode,
            courseName: courseName,
            itemName: itemName,
            previewGrade: previewGrade,
            operationGrade: operationGrade,
            reportGrade: reportGrade,
            totalGrade: totalGrade
        )
    }
}
