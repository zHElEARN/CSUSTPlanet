//
//  CustomGroupBox.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/19.
//

import SwiftUI

struct CustomGroupBox<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat
    var showGroupBox: Bool

    @Environment(\.colorScheme) private var colorScheme

    init(
        showGroupBox: Bool = true,
        cornerRadius: CGFloat = 15,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showGroupBox = showGroupBox
        self.cornerRadius = cornerRadius
        self.content = content
    }

    private var floatingCardColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.09) : Color.white.opacity(0.01)
    }

    private var floatingCardTopBorderColor: Color {
        colorScheme == .dark
            ? Color(red: 254 / 255, green: 254 / 255, blue: 255 / 255, opacity: 0.09)
            : Color(red: 238 / 255, green: 238 / 255, blue: 238 / 255, opacity: 0.20)
    }

    var body: some View {
        Group {
            content()
        }
        .padding(.all, showGroupBox ? nil : 0)
        .background {
            if showGroupBox {
                GeometryReader { geometry in
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black.opacity(0.1))
                            .offset(y: 2)
                            .blur(radius: 2)
                            .mask {
                                Rectangle()
                                    .size(width: geometry.size.width + 18, height: geometry.size.height + 18)
                                    .offset(x: -9, y: -9)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .blendMode(.destinationOut)
                                    }
                            }

                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black.opacity(0.1))
                            .offset(y: 2)
                            .blur(radius: 4)
                            .mask {
                                Rectangle()
                                    .size(width: geometry.size.width + 60, height: geometry.size.height + 60)
                                    .offset(x: -30, y: -30)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .blendMode(.destinationOut)
                                    }
                            }

                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(floatingCardColor)
                    }
                }
            }
        }
        .overlay {
            if showGroupBox {
                LinearGradient(
                    colors: [
                        floatingCardTopBorderColor,
                        floatingCardColor,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.clear)
                        .stroke(.black, style: .init(lineWidth: 1))
                }
                .allowsHitTesting(false)
            }
        }
    }
}
