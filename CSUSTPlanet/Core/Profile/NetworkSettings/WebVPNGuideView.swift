//
//  WebVPNGuideView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/02.
//

import SwiftUI

struct WebVPNGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var globalManager = GlobalManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Text("开启 WebVPN 模式")
                .font(.title3)
                .bold()
                .padding(.top, 16)

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text("WebVPN模式是采用学校官方的WebVPN系统(vpn.csust.edu.cn)来访问校园各个系统")
                Text("当教务系统和网络课程中心只开放了校园内网访问时，可以尝试开启此模式")
                Text("目前此模式处于试验阶段，可能存在问题\n开启后需要重启应用才能生效")
                    .foregroundColor(.red)
                    .font(.headline)
            }
            .padding()

            Spacer()

            VStack(spacing: 10) {
                Button(action: {
                    globalManager.isWebVPNModeEnabled = true
                    exit(0)
                }) {
                    Text("开启并重启应用")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: {
                    dismiss()
                }) {
                    Text("取消")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .presentationDetents([.medium])
    }
}
