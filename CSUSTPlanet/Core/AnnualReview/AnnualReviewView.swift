//
//  AnnualReviewView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import SwiftUI

struct AnnualReviewView: View {
    @StateObject private var viewModel = AnnualReviewViewModel()
    @Binding var isPresented: Bool

    @State private var currentScrollID: Int? = 0

    @State private var isScrollLocked: Bool = false
    @State private var animatedPages: Set<Int> = []

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if viewModel.isLoading {
                    ProgressView("正在生成年度报告...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let data = viewModel.reviewData {
                    ScrollView {
                        VStack(spacing: 0) {
                            AnnualReviewStartPage()
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(0)

                            ProfilePage(
                                data: data,
                                startAnimation: currentScrollID == 1,
                                onAnimationEnd: {
                                    unlockScroll(for: 1)
                                }
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(1)

                            TimeSchedulePage(data: data)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(2)

                            SpacePeoplePage(data: data)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(3)

                            MoocPage(data: data)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(4)

                            GradesPage(data: data)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(5)

                            DormPage(data: data)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(6)

                            AnnualReviewEndPage()
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(7)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: $currentScrollID)
                    .ignoresSafeArea(edges: .bottom)
                    .scrollDisabled(isScrollLocked)
                    .onChange(of: currentScrollID) { oldValue, newID in
                        if let id = newID {
                            handlePageChange(pageID: id)
                        }
                    }

                    GeometryReader { proxy in
                        let totalPages = 8
                        let progress = CGFloat((currentScrollID ?? 0) + 1) / CGFloat(totalPages)

                        ZStack(alignment: .top) {
                            Capsule()
                                .frame(width: 4)
                                .foregroundStyle(.gray.opacity(0.3))

                            Capsule()
                                .frame(width: 4, height: proxy.size.height * progress)
                                .foregroundStyle(.blue)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentScrollID)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .frame(width: 10)
                    .padding(.trailing, 2)
                    .padding(.vertical, 20)
                } else {
                    ContentUnavailableView("无数据", systemImage: "xmark.bin")
                }
            }

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 32, height: 32)
                    .padding(6)
                    .background {
                        if #available(iOS 26.0, *) {
                            Color.clear
                        } else {
                            Circle()
                                .fill(.regularMaterial)
                                .stroke(.primary.opacity(0.05), lineWidth: 0.5)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .contentShape(Circle())
            }
            .apply { view in
                if #available(iOS 26.0, *) {
                    view
                        .background(Circle().fill(.white.opacity(0.01)))
                        .glassEffect()
                        .clipShape(Circle())
                } else {
                    view
                }
            }
            .padding(.top, 15)
            .padding(.trailing, 20)
        }
        .onAppear {
            viewModel.compute()
        }
    }

    private func handlePageChange(pageID: Int) {
        if !animatedPages.contains(pageID) {
            if pageID == 1 {
                lockScroll(for: pageID)
            }
        }
    }

    private func lockScroll(for pageID: Int) {
        isScrollLocked = true
    }

    private func unlockScroll(for pageID: Int) {
        withAnimation {
            isScrollLocked = false
        }
        animatedPages.insert(pageID)
    }
}

#Preview {
    AnnualReviewView(isPresented: .constant(true))
}
