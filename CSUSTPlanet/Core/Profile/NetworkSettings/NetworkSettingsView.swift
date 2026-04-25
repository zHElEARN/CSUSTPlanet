//
//  NetworkSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/3/12.
//

import SwiftUI

struct NetworkSettingsView: View {
    @State var isWebVPNSheetPresented = false
    @State var isWebVPNDisableAlertPresented = false

    var isWebVPNEnabled: Binding<Bool> {
        Binding(
            get: { GlobalManager.shared.isWebVPNModeEnabled },
            set: { handleWebVPNToggle($0) }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: isWebVPNEnabled) {
                    Text("开启WebVPN模式")
                }
            } header: {
                Text("WebVPN")
            } footer: {
                Text("开启后则应用通过学校的WebVPN访问校园网资源")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("网络设置")
        .sheet(isPresented: $isWebVPNSheetPresented) {
            WebVPNGuideView(isPresented: $isWebVPNSheetPresented)
        }
        .alert("关闭 WebVPN 模式", isPresented: $isWebVPNDisableAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("关闭并重启", role: .destructive, action: dismissWebVPNDisableAlert)
        } message: {
            Text("关闭 WebVPN 模式需要重启应用才能生效。")
        }
        .trackView("NetworkSettings")
    }

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

    func dismissWebVPNDisableAlert() {
        GlobalManager.shared.isWebVPNModeEnabled = false
        exit(0)
    }

}
