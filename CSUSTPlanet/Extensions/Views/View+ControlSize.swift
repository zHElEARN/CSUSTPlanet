//
//  View+ControlSize.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/15.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func smallControlSizeOnMac() -> some View {
        #if os(macOS)
        self
            .controlSize(.small)
        #else
        self
        #endif
    }
}
