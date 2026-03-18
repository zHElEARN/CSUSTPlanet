//
//  ProfileDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import AlertToast
import SwiftUI

struct ProfileDetailView: View {
    @State var viewModel = ProfileDetailViewModel()

    var body: some View {
        Form {
            Section {
                if let ssoProfile = viewModel.ssoProfile {
                    FormRow(label: "学生类型", value: ssoProfile.categoryName)
                    FormRow(label: "账号", value: ssoProfile.userAccount)
                    FormRow(label: "用户名", value: ssoProfile.userName)
                    FormRow(label: "手机号", value: ssoProfile.phone)
                    FormRow(label: "邮箱", value: ssoProfile.email ?? "未设置")
                    FormRow(label: "所属院系", value: ssoProfile.deptName)
                } else {
                    ContentUnavailableView(
                        "加载失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text("统一身份认证个人信息加载失败")
                    )
                    .frame(maxWidth: .infinity)
                }
            } header: {
                header(title: "统一身份认证个人信息", isLoading: viewModel.isSSOProfileLoading) {
                    viewModel.loadSSOProfile()
                }
            }

            Section {
                if let eduProfile = viewModel.eduProfile {
                    FormRow(label: "院系", value: eduProfile.department)
                    FormRow(label: "专业", value: eduProfile.major)
                    FormRow(label: "学制", value: eduProfile.educationSystem)
                    FormRow(label: "班级", value: eduProfile.className)
                    FormRow(label: "学号", value: eduProfile.studentID)
                    FormRow(label: "姓名", value: eduProfile.name)
                    FormRow(label: "性别", value: eduProfile.gender)
                    FormRow(label: "名族", value: eduProfile.ethnicity)
                } else {
                    ContentUnavailableView(
                        "加载失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text("教务个人信息加载失败")
                    )
                    .frame(maxWidth: .infinity)
                }
            } header: {
                header(title: "教务个人信息", isLoading: viewModel.isEduProfileLoading) {
                    viewModel.loadEduProfile()
                }
            }

            Section {
                if let moocProfile = viewModel.moocProfile {
                    FormRow(label: "姓名", value: moocProfile.name)
                    FormRow(label: "上次登录时间", value: moocProfile.lastLoginTime)
                    FormRow(label: "总在线时间", value: moocProfile.totalOnlineTime)
                    FormRow(label: "登录次数", value: "\(moocProfile.loginCount)")
                } else {
                    ContentUnavailableView(
                        "加载失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text("网络课程中心个人信息加载失败")
                    )
                    .frame(maxWidth: .infinity)
                }
            } header: {
                header(title: "网络课程中心个人信息", isLoading: viewModel.isMoocProfileLoading) {
                    viewModel.loadMoocProfile()
                }
            }
        }
        .formStyle(.grouped)
        .toast(isPresenting: $viewModel.isShowingError) {
            AlertToast(type: .error(.red), title: "错误", subTitle: viewModel.errorMessage)
        }
        .navigationTitle("个人详情")
        .onAppear {
            viewModel.loadSSOProfile()
            viewModel.loadEduProfile()
            viewModel.loadMoocProfile()
        }
        .trackView("ProfileDetail")
    }

    @ViewBuilder
    func header(title: String, isLoading: Bool, onRefresh: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isLoading {
                ProgressView().smallControlSizeOnMac()
            } else if let onRefresh = onRefresh {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
