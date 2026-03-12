//
//  ProfileViewModel.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import ActivityKit
import CSUSTKit
import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isLoginSheetPresented = false
    @Published var isWebVPNSheetPresented = false
    @Published var isWebVPNDisableAlertPresented = false
    @Published var isLogoutAlertPresented = false

    // MARK: - Computed Properties

    var isWebVPNEnabled: Bool {
        get { GlobalManager.shared.isWebVPNModeEnabled }
        set { handleWebVPNToggle(newValue) }
    }

    // MARK: - Actions

    func showLogoutAlert() {
        isLogoutAlertPresented = true
    }

    func confirmLogout() {
        AuthManager.shared.ssoLogout()
    }

    func dismissWebVPNDisableAlert() {
        GlobalManager.shared.isWebVPNModeEnabled = false
        exit(0)
    }

    // MARK: - Private Methods

    private func handleWebVPNToggle(_ newValue: Bool) {
        let currentValue = GlobalManager.shared.isWebVPNModeEnabled
        if newValue && !currentValue {
            isWebVPNSheetPresented = true
        } else if !newValue && currentValue {
            isWebVPNDisableAlertPresented = true
        } else {
            GlobalManager.shared.isWebVPNModeEnabled = newValue
        }
    }
}
