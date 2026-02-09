//
//  View+Apply.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/9.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyIf<TrueContent: View, FalseContent: View>(_ condition: Bool, @ViewBuilder ifTransform: (Self) -> TrueContent, @ViewBuilder elseTransform: (Self) -> FalseContent) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    @ViewBuilder
    func applyIfLet<Value, Content: View>(_ value: Value?, @ViewBuilder transform: (Self, Value) -> Content) -> some View {
        if let unwrappedValue = value {
            transform(self, unwrappedValue)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyIfLet<Value, TrueContent: View, FalseContent: View>(_ value: Value?, @ViewBuilder ifTransform: (Self, Value) -> TrueContent, @ViewBuilder elseTransform: (Self) -> FalseContent) -> some View {
        if let unwrappedValue = value {
            ifTransform(self, unwrappedValue)
        } else {
            elseTransform(self)
        }
    }

    @ViewBuilder
    func apply<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> some View {
        transform(self)
    }
}
