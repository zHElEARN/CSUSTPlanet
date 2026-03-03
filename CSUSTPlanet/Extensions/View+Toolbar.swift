//
//  View+Toolbar.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/3.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func inlineToolbarTitle() -> some View {
        #if os(iOS)
        self.toolbarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
