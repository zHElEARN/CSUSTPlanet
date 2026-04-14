//
//  WebVPNGuideView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/02.
//

import SwiftUI

struct WebVPNGuideView: View {
    @Binding var isPresented: Bool
    @Bindable var globalManager = GlobalManager.shared

    var body: some View {
        VStack(spacing: 16) {
            #if os(macOS)
            Text("开启校园网关模式")
                .font(.title3)
                .bold()
                .padding(.top, 16)
            #else
            Text("开启 WebVPN 模式")
                .font(.title3)
                .bold()
                .padding(.top, 16)
            #endif

            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                #if os(macOS)
                Text("校园网关模式是通过学校官方的网关门户进行链接转换，从而实现对校内各个系统的跨网访问。")
                Text("当教务系统和网络课程中心仅限校园内网环境访问时，您可以尝试开启此模式。")
                Text("目前此模式处于试验阶段，可能存在不稳定情况\n开启后需要重启应用才能生效")
                    .foregroundColor(.red)
                    .font(.headline)
                #else
                Text("WebVPN模式是采用学校官方的WebVPN系统(vpn.csust.edu.cn)来访问校园各个系统")
                Text("当教务系统和网络课程中心只开放了校园内网访问时，可以尝试开启此模式")
                Text("目前此模式处于试验阶段，可能存在问题\n开启后需要重启应用才能生效")
                    .foregroundColor(.red)
                    .font(.headline)
                #endif
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
                    isPresented = false
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
        .trackView("WebVPNGuide")
    }
}
