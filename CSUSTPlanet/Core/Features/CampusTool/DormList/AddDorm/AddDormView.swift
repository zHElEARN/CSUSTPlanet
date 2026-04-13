//
//  AddDormView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import SwiftUI

struct AddDormView: View {
    @Binding var isPresented: Bool
    var onConfirm: (_ building: CampusCardHelper.Building, _ room: String) -> Void
    @State var viewModel = AddDormViewModel()

    var roomPlaceholder: String {
        viewModel.selectedCampus == .jinpenling ? "例如: 101" : "例如: A101 或 B203"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("校区", selection: $viewModel.selectedCampus) {
                        ForEach(CampusCardHelper.Campus.allCases, id: \.self) { campus in
                            Text(campus.rawValue).tag(campus)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("校区")
                }

                Section {
                    if !viewModel.isBuildingsLoading {
                        Picker("宿舍楼", selection: $viewModel.selectedBuildingID) {
                            ForEach(viewModel.selectedCampusBuildings, id: \.id) { building in
                                Text(building.name).tag(building.id)
                            }
                        }
                        #if os(iOS)
                        .pickerStyle(.wheel)
                        #elseif os(macOS)
                        .pickerStyle(.menu)
                        #endif
                        .disabled(viewModel.selectedCampusBuildings.isEmpty)
                    }

                    HStack {
                        Button(asyncAction: viewModel.loadBuildings) {
                            Label("刷新宿舍楼", systemImage: "arrow.clockwise")
                        }
                        Spacer()
                        if viewModel.isBuildingsLoading {
                            ProgressView().smallControlSizeOnMac()
                        }
                    }
                } header: {
                    Text("宿舍楼")
                }

                Section {
                    TextField(roomPlaceholder, text: $viewModel.room)
                        #if os(iOS)
                    .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled(true)
                } header: {
                    Text("宿舍号")
                } footer: {
                    Text("房间号填写提示: 金盆岭校区不分A/B区，直接输入门牌号即可（如101）；云塘校区需加A/B前缀（如B306、A504）。")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("添加宿舍")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        guard let building = viewModel.selectedBuilding else {
                            viewModel.errorToast.show(message: "请选择宿舍楼")
                            return
                        }
                        onConfirm(building, viewModel.trimmedRoom)
                        isPresented = false
                    }
                    .disabled(viewModel.selectedBuildingID.isEmpty || viewModel.trimmedRoom.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
            }
            .task { await viewModel.loadInitial() }
            .onChange(of: viewModel.selectedCampus, viewModel.handleCampusPickerChange)
            .errorToast($viewModel.errorToast)
        }
    }
}
