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

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("正在生成年度报告...")
                } else if let data = viewModel.reviewData {
                    TabView {
                        ProfilePage(data: data)
                            .tag(0)

                        TimeSchedulePage(data: data)
                            .tag(1)

                        SpacePeoplePage(data: data)
                            .tag(2)

                        if data.moocAvailable {
                            MoocPage(data: data)
                                .tag(3)
                        }
                        GradesPage(data: data)
                            .tag(4)

                        DormPage(data: data)
                            .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                } else {
                    ContentUnavailableView("无数据", systemImage: "xmark.bin")
                }
            }
            .navigationTitle("2025 年度报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                viewModel.compute()
            }
        }
    }
}

#Preview {
    AnnualReviewView(isPresented: .constant(true))
}
