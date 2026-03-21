//
//  DormListView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import SwiftUI

struct DormListView: View {
    @State var viewModel = DormListViewModel()

    var body: some View {
        Group {
            if viewModel.dorms.isEmpty {
                ContentUnavailableView("暂无宿舍", systemImage: "building.2", description: Text("点击右上角添加宿舍"))
            } else {
                List {
                    ForEach(viewModel.dorms) { dorm in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(dorm.buildingName) \(dorm.room)")
                            Text(dorm.campusName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("宿舍列表")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.isAddDormSheetPresented = true }) {
                    Label("添加宿舍", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isAddDormSheetPresented) {
            AddDormView(isPresented: $viewModel.isAddDormSheetPresented) { building, room in
                viewModel.addDorm(building: building, room: room)
            }
        }
        .task {
            viewModel.startObserveDorms()
        }
        .errorToast($viewModel.errorToast)
        .trackView("DormListView")
    }
}
