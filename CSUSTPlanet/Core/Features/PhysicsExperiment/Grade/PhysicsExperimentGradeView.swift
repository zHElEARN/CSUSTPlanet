//
//  PhysicsExperimentGradeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import AlertToast
import CSUSTKit
import SwiftUI

struct PhysicsExperimentGradeView: View {
    @State var viewModel = PhysicsExperimentGradeViewModel()
    @State private var isLoginPresented: Bool = false

    var body: some View {
        Group {
            Form {
                if viewModel.data.isEmpty {
                    ContentUnavailableView("暂无成绩信息", systemImage: "chart.bar.doc.horizontal", description: Text("没有找到任何大物实验成绩信息"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Section {
                        ForEach(viewModel.data, id: \.itemName) { grade in
                            gradeCard(grade: grade)
                        }
                    }
                }
            }
            .formStyle(.grouped)
        }
        .errorToast($viewModel.errorToast)
        .sheet(isPresented: $isLoginPresented) {
            PhysicsExperimentLoginView()
        }
        .onChange(of: isLoginPresented) { _, newValue in
            if !newValue { Task { await viewModel.loadGrades() } }
        }
        .task { await viewModel.loadInitial() }
        .safeRefreshable { await viewModel.loadGrades() }
        .navigationTitle("大物实验成绩")
        .navigationSubtitleCompat("共\(viewModel.data.count)项成绩")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { isLoginPresented = true }) {
                    Text("登录")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: viewModel.loadGrades) {
                    if viewModel.isLoadingGrades {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoadingGrades)
            }
        }
    }

    // MARK: - Form Sections

    private func gradeCard(grade: PhysicsExperimentHelper.CourseGrade) -> some View {
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
        .padding(.vertical, 6)
    }

    private func infoItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.small)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
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

#Preview {
    PhysicsExperimentGradeView()
}
