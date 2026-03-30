//
//  LastUpdatedDateView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/30.
//

import SwiftUI

struct LastUpdatedDateView: View {
    let lastUpdated: Date
    let font: Font
    let foregroundStyle: AnyShapeStyle
    var prefix: String = "更新于："

    init<S: ShapeStyle>(
        lastUpdated: Date,
        font: Font,
        foregroundStyle: S,
        prefix: String = "更新于："
    ) {
        self.lastUpdated = lastUpdated
        self.font = font
        self.foregroundStyle = AnyShapeStyle(foregroundStyle)
        self.prefix = prefix
    }

    var body: some View {
        styled(Text(prefix))
            + styled(Text(lastUpdated, style: .relative))
            + styled(Text("前"))
    }

    private func styled(_ text: Text) -> Text {
        text
            .font(font)
            .foregroundStyle(foregroundStyle)
    }
}
