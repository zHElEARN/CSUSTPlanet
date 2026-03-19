//
//  Binding+Animation.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/19.
//

import SwiftUI

extension Binding {
    /// 返回一个新的 Binding，在 set 时自动包裹 withAnimation
    func withAnimation(_ animation: Animation? = .default) -> Binding {
        Binding(
            get: { wrappedValue },
            set: { newValue in
                SwiftUI.withAnimation(animation) {
                    wrappedValue = newValue
                }
            }
        )
    }
}
