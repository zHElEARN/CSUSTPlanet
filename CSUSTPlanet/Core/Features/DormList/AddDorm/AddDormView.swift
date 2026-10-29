//
//  AddDormView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/21.
//

import CSUSTKit
import SwiftUI

struct AddDormView: View {
    @Environment(\.dismiss) private var dismiss

    var onConfirm: (_ room: CampusCardHelper.Room) -> Void

    @State private var selectedCampus: CampusCardHelper.Campus = .jinpenling
    @State private var selectedBuilding: CampusCardHelper.Building?
    @State private var selectedRoom: CampusCardHelper.Room?

    @State private var buildings: [CampusCardHelper.Building] = []
    @State private var rooms: [CampusCardHelper.Room] = []

    @State private var errorToast: ToastState = .errorTitle
    @State private var isInitial = true

    var body: some View {
        AddDormContent(
            selectedCampus: $selectedCampus,
            selectedBuilding: $selectedBuilding,
            selectedRoom: $selectedRoom,
            buildings: buildings,
            rooms: rooms,
            errorToast: $errorToast,
            onCancel: { dismiss() },
            onConfirm: confirm
        )
        .task {
            guard isInitial else { return }
            isInitial = false
            await loadBuildings()
        }
        .onChange(of: selectedCampus) { oldValue, newValue in
            guard oldValue != newValue else { return }

            buildings = []
            selectedBuilding = nil
            rooms = []
            selectedRoom = nil
            Task { await loadBuildings() }
        }
        .onChange(of: selectedBuilding) { oldValue, newValue in
            guard oldValue != newValue else { return }

            rooms = []
            selectedRoom = nil
            Task { await loadRooms() }
        }
    }

    // MARK: - Actions

    private func confirm() {
        guard let room = selectedRoom else { return }
        onConfirm(room)
        dismiss()
    }

    // MARK: - Loading

    private func loadBuildings() async {
        do {
            buildings = try await ElectricityUtil.getBuildings(
                AuthManager.shared.campusCardHelper,
                selectedCampus,
                useCache: false,
                retryProvider: AuthManager.shared
            ).sorted { $0.name < $1.name }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func loadRooms() async {
        guard let selectedBuilding else { return }

        do {
            rooms = try await ElectricityUtil.getRooms(
                AuthManager.shared.campusCardHelper,
                selectedBuilding,
                useCache: false,
                retryProvider: AuthManager.shared
            ).sorted { $0.name < $1.name }
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
