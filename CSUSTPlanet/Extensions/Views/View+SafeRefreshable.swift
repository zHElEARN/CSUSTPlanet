//
//  View+SafeRefreshable.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/19.
//

import SwiftUI

extension View {
    func safeRefreshable(action: @Sendable @escaping () async -> Void) -> some View {
        self.refreshable {
            let task = Task {
                await action()
            }
            _ = await task.result
        }
    }
}
