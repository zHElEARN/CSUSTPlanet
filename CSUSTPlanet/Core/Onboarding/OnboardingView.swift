//
//  OnboardingView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingView: View {
    let onSkip: () -> Void

    @State private var currentPage = 0
    @State private var dormViewModel = DormListViewModel()

    private let totalPages = 5

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    switch currentPage {
                    case 0:
                        OnboardingWelcomePage()
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case 1:
                        OnboardingLoginPage()
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case 2:
                        OnboardingDormSetupPage(viewModel: dormViewModel)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    case 3:
                        OnboardingDormNotificationPage(viewModel: dormViewModel)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    default:
                        OnboardingCompletionPage()
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.18))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.snappy(duration: 0.22), value: currentPage)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task { await dormViewModel.loadInitial() }
            .navigationTitle("欢迎进入长理星球")
            .navigationSubtitleCompat("步骤 \(currentPage + 1) / \(totalPages)")
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳过", action: onSkip)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(currentPage == totalPages - 1 ? "开始使用" : "下一步", action: handlePrimaryAction)
                }
            }
        }
    }

    private func handlePrimaryAction() {
        if currentPage == totalPages - 1 {
            onSkip()
            return
        }

        withAnimation(.snappy(duration: 0.28)) {
            currentPage += 1
        }
    }
}
