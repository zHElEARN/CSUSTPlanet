//
//  ProfileDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/8.
//

import SwiftUI

struct ProfileDetailView: View {
    @StateObject private var viewModel: ProfileDetailViewModel

    init(authManager: AuthManager) {
        _viewModel = StateObject(
            wrappedValue: ProfileDetailViewModel(
                ssoHelper: authManager.ssoHelper,
                eduHelper: authManager.eduHelper,
                moocHelper: authManager.moocHelper,
                ssoProfile: authManager.ssoProfile
            ))
    }

    var body: some View {
        Form {
            Section(header: Text("统一认证信息")) {
                if viewModel.isSSOProfileLoading {
                    LoadingView()
                } else if let ssoProfile = viewModel.ssoProfile {
                    InfoRow(label: "学生类型", value: ssoProfile.categoryName)
                    InfoRow(label: "账号", value: ssoProfile.userAccount)
                    InfoRow(label: "用户名", value: ssoProfile.userName)
                    InfoRow(label: "手机号", value: ssoProfile.phone)
                    InfoRow(label: "邮箱", value: ssoProfile.email ?? "未设置")
                    InfoRow(label: "所属院系", value: ssoProfile.deptName)
                } else {
                    ContentUnavailableView(
                        "加载失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text("统一认证信息加载失败")
                    )
                }
            }

            Section {
                if viewModel.isEduProfileLoading {
                    LoadingView()
                } else if let eduProfile = viewModel.eduProfile {
                    InfoRow(label: "院系", value: eduProfile.department)
                    InfoRow(label: "专业", value: eduProfile.major)
                    InfoRow(label: "学制", value: eduProfile.educationSystem)
                    InfoRow(label: "班级", value: eduProfile.className)
                    InfoRow(label: "学号", value: eduProfile.studentID)
                    InfoRow(label: "姓名", value: eduProfile.name)
                    InfoRow(label: "性别", value: eduProfile.gender)
                    InfoRow(label: "名族", value: eduProfile.ethnicity)
                } else {
                    ContentUnavailableView(
                        "加载失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text("教务信息加载失败")
                    )
                }
            } header: {
                SectionHeaderWithRefresh(title: "教务信息") {
                    viewModel.loadEduProfile()
                }
            }

            Section {
                if viewModel.isMoocProfileLoading {
                    LoadingView()
                } else if let moocProfile = viewModel.moocProfile {
                    InfoRow(label: "姓名", value: moocProfile.name)
                    InfoRow(label: "上次登录时间", value: moocProfile.lastLoginTime)
                    InfoRow(label: "总在线时间", value: moocProfile.totalOnlineTime)
                    InfoRow(label: "登录次数", value: "\(moocProfile.loginCount)")
                } else {
                    ContentUnavailableView(
                        "加载失败",
                        systemImage: "exclamationmark.triangle",
                        description: Text("网络课程中心信息加载失败")
                    )
                }
            } header: {
                SectionHeaderWithRefresh(title: "网络课程中心信息") {
                    viewModel.loadMoocProfile()
                }
            }
        }
        .alert("错误", isPresented: $viewModel.isShowingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .navigationTitle("个人详情")
        .onAppear {
            viewModel.loadEduProfile()
            viewModel.loadMoocProfile()
        }
        .trackView("ProfileDetail")
    }

    struct SectionHeaderWithRefresh: View {
        let title: String
        let onRefresh: () -> Void

        var body: some View {
            HStack {
                Text(title)
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    struct LoadingView: View {
        var body: some View {
            HStack {
                Spacer()
                ProgressView("加载中...")
                Spacer()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileDetailView(authManager: AuthManager.shared)
    }
}
