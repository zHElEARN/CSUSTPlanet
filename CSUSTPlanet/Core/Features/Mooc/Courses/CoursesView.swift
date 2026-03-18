//
//  CoursesView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/14.
//

import CSUSTKit
import SwiftUI

struct CoursesView: View {
    @State var viewModel = CoursesViewModel()

    var body: some View {
        Group {
            if viewModel.filteredCourses.isEmpty {
                ContentUnavailableView("暂无课程信息", systemImage: "book.closed", description: Text(viewModel.searchText.isEmpty ? "没有找到任何课程信息" : "没有找到匹配的课程"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                    Section {
                        ForEach(viewModel.filteredCourses, id: \.self) { course in
                            TrackLink(destination: CourseDetailView(course: course)) {
                                courseRow(course: course)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索课程")
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task { await viewModel.task() }
        .navigationTitle("课程列表")
        .apply { view in
            if #available(iOS 26.0, *) {
                view.navigationSubtitle("共\(viewModel.courses.count)门课程")
            } else {
                view
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.loadCourses) {
                    if viewModel.isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
        .trackView("Courses")
    }

    @ViewBuilder
    private func courseRow(course: MoocHelper.Course) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                infoItem(icon: "person.fill", color: .purple, text: course.teacher)
                infoItem(icon: "building.columns.fill", color: .green, text: course.department)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
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
}
