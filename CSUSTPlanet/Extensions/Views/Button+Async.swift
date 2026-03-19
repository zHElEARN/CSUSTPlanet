//
//  Button+Async.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/19.
//

import SwiftUI

extension Button {
    init(_ titleKey: LocalizedStringKey, role: ButtonRole? = nil, asyncAction: @escaping () async -> Void) where Label == Text {
        self.init(titleKey, role: role) {
            Task { await asyncAction() }
        }
    }

    init<S: StringProtocol>(_ title: S, role: ButtonRole? = nil, asyncAction: @escaping () async -> Void) where Label == Text {
        self.init(title, role: role) {
            Task { await asyncAction() }
        }
    }

    init(role: ButtonRole? = nil, asyncAction: @escaping () async -> Void, @ViewBuilder label: () -> Label) {
        self.init(
            role: role,
            action: {
                Task { await asyncAction() }
            },
            label: label
        )
    }
}
