//
//  ChaoxingAssignmentsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import CSUSTKit
import SwiftUI

struct ChaoxingAssignmentsView: View {
    @State private var assignments: [ChaoxingHelper.Assignment]?

    @State private var isLoading = false

    @State private var errorToast: ToastState = .errorTitle

    @State private var isInitial = true

    var body: some View {
        ChaoxingAssignmentsContent(
            assignments: assignments,
            isLoading: isLoading,
            errorToast: $errorToast,
            onRefreshAssignments: loadAssignments
        )
        .onReceive(MMKVHelper.ChaoxingAssignments.$cache.dropFirst().receive(on: RunLoop.main)) { data in
            applyData(data)
        }
        .task {
            guard isInitial else {
                return
            }
            isInitial = false
            applyData(MMKVHelper.ChaoxingAssignments.cache)
            await loadAssignments()
        }
    }

    // MARK: - Methods

    private func loadAssignments() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedAssignments = try await AuthManager.shared.withAuthRetry(system: .chaoxing) {
                try await AuthManager.shared.chaoxingHelper.getAssignments()
            }
            MMKVHelper.ChaoxingAssignments.cache = Cached(cachedAt: .now, value: fetchedAssignments)
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    private func applyData(_ data: Cached<[ChaoxingHelper.Assignment]>?) {
        assignments = data?.value
    }
}
