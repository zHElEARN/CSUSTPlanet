//
//  CourseSemesterView.swift
//  CSUSTPlanet
//
//  Created by liuzeyun on 2025/9/8.
//

import SwiftUI

struct CourseSemesterView: View {
    @Bindable var viewModel: CourseScheduleViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("学期选择") {
                    Picker("学期", selection: $viewModel.selectedSemester) {
                        Text("默认学期").tag(nil as String?)
                        ForEach(viewModel.availableSemesters, id: \.self) { semester in
                            Text(semester).tag(semester as String?)
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.wheel)
                    #elseif os(macOS)
                    .pickerStyle(.menu)
                    #endif
                }
                HStack {
                    Button(asyncAction: viewModel.loadAvailableSemesters) {
                        Text("刷新学期列表")
                    }
                    .disabled(viewModel.isSemestersLoading)
                    if viewModel.isSemestersLoading {
                        Spacer()
                        ProgressView().smallControlSizeOnMac()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        await viewModel.loadCourses()
                        viewModel.isSemestersSheetPresented = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        viewModel.isSemestersSheetPresented = false
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("学期选择")
            .inlineToolbarTitle()
        }
    }
}
