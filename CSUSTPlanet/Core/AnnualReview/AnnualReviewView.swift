//
//  AnnualReviewView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import SwiftUI

struct AnnualReviewView: View {
    @StateObject private var viewModel = AnnualReviewViewModel()

    var body: some View {
        ScrollView {
        }
        .onAppear {
            viewModel.compute()
        }
    }
}

#Preview {
    AnnualReviewView()
}
