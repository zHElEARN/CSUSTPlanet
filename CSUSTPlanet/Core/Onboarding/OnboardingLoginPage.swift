//
//  OnboardingLoginPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import CSUSTKit
import Kingfisher
import SwiftUI

struct OnboardingLoginPage: View {
    @Bindable var authManager = AuthManager.shared

    @State private var isLoginSheetPresented = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                actionCard
                footerText
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $isLoginSheetPresented) {
            SSOLoginView(isPresented: $isLoginSheetPresented)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: authManager.isSSOLoggedIn ? "checkmark.circle.fill" : "person.crop.circle")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(authManager.isSSOLoggedIn ? .green : .secondary)
                .padding(.top, 16)

            Text(authManager.isSSOLoggedIn ? "统一身份认证已登录" : "登录您的账号")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(authManager.isSSOLoggedIn ? "您已完成账号登录，后续可以直接使用课表、成绩查询、未提交作业查询等功能。" : "登录统一身份认证后，您可以使用课表、成绩查询、未提交作业查询等功能。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var actionCard: some View {
        if authManager.isSSOLoggedIn {
            CustomGroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    loggedInProfileContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 6)
        } else if authManager.isSSOLoggingIn {
            HStack(spacing: 12) {
                ProgressView()
                    .smallControlSizeOnMac()

                Text("正在登录统一身份认证...")
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 6)
        } else {
            Button(action: { isLoginSheetPresented = true }) {
                Text("登录统一认证账号")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 6)
        }
    }

    private var footerText: some View {
        Text("您也可以稍后在“我的”页面继续进行账号管理。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var loggedInProfileContent: some View {
        if let ssoProfile = authManager.ssoProfile {
            HStack(spacing: 14) {
                avatarView(for: ssoProfile)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ssoProfile.userName)
                        .font(.headline)

                    Text(ssoProfile.userAccount)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(ssoProfile.deptName)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func avatarView(for profile: SSOHelper.Profile) -> some View {
        if let avatarURL = URL(string: profile.avatar) {
            let resource = KF.ImageResource(
                downloadURL: avatarURL,
                cacheKey: avatarURL.absoluteString.components(separatedBy: "?").first ?? profile.avatar
            )

            KFImage(source: .network(resource))
                .placeholder {
                    ProgressView()
                        .smallControlSizeOnMac()
                }
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
