//
//  AnnualReviewView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import SwiftUI

struct AnnualReviewView: View {
    @StateObject private var viewModel = AnnualReviewViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
            }
            .onAppear {
                viewModel.compute()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    AnnualReviewView(isPresented: .constant(true))
}
