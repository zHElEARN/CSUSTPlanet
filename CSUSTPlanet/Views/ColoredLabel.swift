//
//  ColoredLabel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/19.
//

import SwiftUI

struct ColoredLabel: View {
    let title: String
    let description: String?
    let iconName: String?
    let color: Color
    let textColor: Color

    init(title: String, iconName: String? = nil, color: Color? = nil, textColor: Color? = nil, description: String? = nil) {
        self.title = title
        self.iconName = iconName
        self.color = color ?? .blue
        self.textColor = textColor ?? .primary
        self.description = description
    }

    private var labelTitle: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(textColor)
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.7))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var body: some View {
        if let iconName = iconName {
            Label {
                labelTitle
            } icon: {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 29, height: 29)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(color.gradient)
                    )
            }
        } else {
            labelTitle
        }
    }
}
