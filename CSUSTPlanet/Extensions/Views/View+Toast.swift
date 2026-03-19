//
//  View+Toast.swift
//  CSUSTPlanet
//
//  Created by Claude on 2026/3/18.
//

import AlertToast
import SwiftUI

struct ToastState {
    var isPresenting: Bool = false
    var message: String = ""

    mutating func show(message: String) {
        self.message = message
        self.isPresenting = true
    }
}

extension View {
    func errorToast(isPresenting: Binding<Bool>, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(type: .error(.red), title: "错误", subTitle: message)
        }
    }

    func warningToast(isPresenting: Binding<Bool>, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: "警告", subTitle: message)
        }
    }

    func successToast(isPresenting: Binding<Bool>, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(type: .complete(.green), title: message)
        }
    }

    func errorToast(_ state: Binding<ToastState>) -> some View {
        errorToast(isPresenting: state.isPresenting, message: state.wrappedValue.message)
    }

    func warningToast(_ state: Binding<ToastState>) -> some View {
        warningToast(isPresenting: state.isPresenting, message: state.wrappedValue.message)
    }

    func successToast(_ state: Binding<ToastState>) -> some View {
        successToast(isPresenting: state.isPresenting, message: state.wrappedValue.message)
    }
}
