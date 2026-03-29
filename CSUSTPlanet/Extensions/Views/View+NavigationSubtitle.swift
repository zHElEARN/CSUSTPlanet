//
//  View+NavigationSubtitle.swift
//  CSUSTPlanet
//
//  Created by Claude on 2026/3/18.
//

import SwiftUI

extension View {
    @ViewBuilder
    func navigationSubtitleCompat(_ subtitle: String) -> some View {
        #if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
        if #available(iOS 26.0, macOS 26.0, *) {
            self.navigationSubtitle(subtitle)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
