//
//  Color+Theme.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/3.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    /// 替代 Color(uiColor: .systemGroupedBackground)
    static var appSystemGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .secondarySystemBackground)
    static var appSecondarySystemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .secondarySystemGroupedBackground)
    static var appSecondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .systemBackground)
    static var appSystemBackground: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #elseif os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .tertiaryLabel)
    static var appTertiaryLabel: Color {
        #if os(iOS)
        return Color(uiColor: .tertiaryLabel)
        #elseif os(macOS)
        return Color(nsColor: .tertiaryLabelColor)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .tertiarySystemFill)
    static var appTertiarySystemFill: Color {
        #if os(iOS)
        return Color(uiColor: .tertiarySystemFill)
        #elseif os(macOS)
        return Color.primary.opacity(0.12)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .systemGray6)
    static var appSystemGray6: Color {
        #if os(iOS)
        return Color(uiColor: .systemGray6)
        #elseif os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color.clear
        #endif
    }

    /// 替代 Color(uiColor: .systemGray4)
    static var appSystemGray4: Color {
        #if os(iOS)
        return Color(uiColor: .systemGray4)
        #elseif os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color.clear
        #endif
    }
}
