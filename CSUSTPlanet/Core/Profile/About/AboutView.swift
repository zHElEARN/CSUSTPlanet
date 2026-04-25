//
//  AboutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/9.
//

import MarkdownUI
import SwiftUI

struct AboutView: View {
    @State private var viewModel = AboutViewModel()

    var body: some View {
        Form {
            if let aboutMarkdown = viewModel.aboutMarkdown {
                Markdown(aboutMarkdown)
            } else {
                Text("无法加载关于信息")
            }

            Section("应用信息") {
                FormRow(label: "版本号", value: viewModel.appVersion)
                FormRow(label: "构建号", value: viewModel.buildNumber)
                FormRow(label: "运行环境", value: viewModel.environment)
            }

            Section("更多信息") {
                NavigationLink(value: AppRoute.profile(.about(.openSourceLicenses(.main)))) {
                    Text("开源许可")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("关于")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
