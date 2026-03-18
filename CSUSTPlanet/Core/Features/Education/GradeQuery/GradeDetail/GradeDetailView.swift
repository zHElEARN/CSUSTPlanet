//
//  GradeDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import AlertToast
import CSUSTKit
import Charts
import SwiftUI

struct GradeDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @State var viewModel = GradeDetailViewModel()

    var courseGrade: EduHelper.CourseGrade

    // MARK: - Course Title

    private var courseTitle: some View {
        Text(courseGrade.courseName)
            .font(.largeTitle)
            .bold()
            .padding(.horizontal)
    }

    // MARK: - Score Item

    private func scoreItem(value: String, label: String, color: Color) -> some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Scores Section

    private var scoresSection: some View {
        HStack(alignment: .top, spacing: 16) {
            scoreItem(value: "\(courseGrade.grade)", label: "总成绩", color: ColorUtil.dynamicColor(grade: Double(courseGrade.grade)))
            scoreItem(value: String(format: "%.1f", courseGrade.gradePoint), label: "绩点", color: ColorUtil.dynamicColor(point: courseGrade.gradePoint))
            scoreItem(value: String(format: "%.1f", courseGrade.credit), label: "学分", color: .primary)
            scoreItem(value: "\(courseGrade.totalHours)", label: "学时", color: .primary)
        }
        .padding(.horizontal)
    }

    // MARK: - Distribution Chart

    @ViewBuilder
    private var distributionChart: some View {
        let gradeRenderModeBinding = Binding(
            get: { viewModel.gradeRenderMode },
            set: { newValue in withAnimation { viewModel.gradeRenderMode = newValue } }
        )

        if let detail = viewModel.gradeDetail {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Text("成绩分布")
                        .font(.headline)
                    Spacer()
                    Picker("显示方式", selection: gradeRenderModeBinding) {
                        ForEach(GradeDetailViewModel.GradeRenderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.gradeRenderMode == .pie {
                        Chart(detail.components, id: \.type) { component in
                            SectorMark(
                                angle: .value("占比", component.ratio),
                                innerRadius: .ratio(0.4),
                                angularInset: 1
                            )
                            .foregroundStyle(by: .value("类型", component.type))
                            .annotation(position: .overlay) {
                                VStack {
                                    Text(String(format: "%.1f", component.grade))
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .bold()
                                    Text("(\(component.ratio)%)")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }
                        .frame(height: 250)
                        .chartLegend(position: .bottom, alignment: .center, spacing: 10)
                        .padding(.horizontal)
                    } else {
                        ForEach(detail.components, id: \.type) { component in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(component.type) (\(component.ratio)%)")
                                        .font(.callout)
                                    Spacer()
                                    Text("\(String(format: "%.1f", component.grade))/100")
                                        .font(.callout)
                                        .foregroundColor(.secondary)
                                }

                                ProgressView(value: min(max(component.grade, 0), 100), total: 100)
                                    .tint(ColorUtil.dynamicColor(grade: component.grade))
                            }
                        }
                    }
                }
                .padding()
                #if os(iOS)
                .background(Color(PlatformColor.secondarySystemGroupedBackground))
                #else
                .background(Color(PlatformColor.controlBackgroundColor))
                #endif
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Detail Row

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.callout)
                .multilineTextAlignment(.trailing)
        }
    }

    // MARK: - Course Info Section

    private var courseInfoSection: some View {
        infoGroupBox(title: "课程信息") {
            detailRow(label: "课程编号", value: courseGrade.courseID)
            detailRow(label: "开课学期", value: courseGrade.semester)
            if !courseGrade.groupName.isEmpty {
                detailRow(label: "分组名", value: courseGrade.groupName)
            }
            detailRow(label: "修读方式", value: courseGrade.studyMode)
            detailRow(label: "课程性质", value: courseGrade.courseNature.rawValue)
            if !courseGrade.courseCategory.isEmpty {
                detailRow(label: "课程类别", value: courseGrade.courseCategory)
            }
            detailRow(label: "课程属性", value: courseGrade.courseAttribute)
            detailRow(label: "考核方式", value: courseGrade.assessmentMethod)
            detailRow(label: "考试性质", value: courseGrade.examNature)
        }
    }

    // MARK: - Info Group Box

    private func infoGroupBox<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.leading)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            #if os(iOS)
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            #else
            .background(Color(PlatformColor.controlBackgroundColor))
            #endif
            .cornerRadius(12)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                courseTitle
                scoresSection
                distributionChart
                courseInfoSection
            }
            .padding()
        }
        #if os(iOS)
        .background(Color(PlatformColor.systemGroupedBackground))
        #endif
        .task { viewModel.task(courseGrade) }
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .toast(isPresenting: $viewModel.isShowingWarning) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: viewModel.warningMessage)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.loadDetail(courseGrade) }) {
                    if viewModel.isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新成绩分布", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .trackView("GradeDetail")
    }
}
