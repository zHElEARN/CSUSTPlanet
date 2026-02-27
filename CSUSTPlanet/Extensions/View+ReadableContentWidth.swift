//
//  View+ReadableContentWidth.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/27.
//

import Foundation
import SwiftUI

struct ReadableContentWidthModifier: ViewModifier {
    var maximumWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maximumWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    /// 限制视图的最大宽度，并在可用空间内居中显示。
    /// 适用于适配 iPad 大屏阅读和表单页。
    /// - Parameter maximumWidth: 最大宽度限制，默认值为 672
    func readableContentWidth(_ maximumWidth: CGFloat = 672) -> some View {
        self.modifier(ReadableContentWidthModifier(maximumWidth: maximumWidth))
    }
}
