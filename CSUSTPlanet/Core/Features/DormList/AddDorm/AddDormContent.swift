//
//  AddDormContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/29.
//

import CSUSTKit
import SwiftUI

extension CampusCardHelper.Building: @retroactive Identifiable {}
extension CampusCardHelper.Room: @retroactive Identifiable {}

struct AddDormContent: View {
    @Binding var selectedCampus: CampusCardHelper.Campus
    @Binding var selectedBuilding: CampusCardHelper.Building?
    @Binding var selectedRoom: CampusCardHelper.Room?

    let buildings: [CampusCardHelper.Building]
    let rooms: [CampusCardHelper.Room]

    @Binding var errorToast: ToastState

    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("校区", selection: $selectedCampus) {
                        ForEach(CampusCardHelper.Campus.allCases, id: \.self) { campus in
                            Text(campus.rawValue).tag(campus)
                        }
                    }

                    Picker("宿舍楼", selection: $selectedBuilding) {
                        Text("请选择").tag(nil as CampusCardHelper.Building?)
                        ForEach(buildings) { building in
                            Text(building.name).tag(building)
                        }
                    }
                    .disabled(buildings.isEmpty)

                    Picker("宿舍", selection: $selectedRoom) {
                        Text("请选择").tag(nil as CampusCardHelper.Room?)
                        ForEach(rooms) { room in
                            Text(room.name).tag(room)
                        }
                    }
                    .disabled(rooms.isEmpty)
                } header: {
                    Text("宿舍信息")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("添加宿舍")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成", action: onConfirm)
                        .disabled(selectedRoom == nil)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消", action: onCancel)
                }
            }
            .errorToast($errorToast)
        }
    }
}
