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
        ListPageScaffold(
            title: "大物实验成绩",
            subtitle: "共\(grades?.count ?? 0)项成绩",
            isEmpty: grades?.isEmpty ?? true,
            isLoading: isLoadingGrades,
            emptyNoun: "大物实验成绩",
            errorToast: $errorToast,
            onQuery: onRefreshGrades
        ) {
            ForEach(grades ?? [], id: \.itemName) { grade in
                GradeCardView(grade: grade)
            }
        }
        .sheet(isPresented: $isLoginPresented) {
            PhysicsExperimentLoginView()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { isLoginPresented = true }) {
                    Text("登录")
                }
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

#Preview("Normal") {
    NavigationStack {
        PhysicsExperimentGradeContent(
            grades: PhysicsExperimentGradePreviewData.grades,
            isLoadingGrades: false,
            isLoginPresented: .constant(false),
            errorToast: .constant(.errorTitle),
            onRefreshGrades: {}
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        PhysicsExperimentGradeContent(
            grades: [],
            isLoadingGrades: false,
            isLoginPresented: .constant(false),
            errorToast: .constant(.errorTitle),
            onRefreshGrades: {}
        )
    }
}
