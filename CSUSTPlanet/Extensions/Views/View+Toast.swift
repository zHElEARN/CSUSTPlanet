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
    var title: String = ""
    var message: String = ""

    init(title: String = "", message: String = "") {
        self.title = title
        self.message = message
    }

    static var warningTitle: ToastState { ToastState(title: "警告") }

    static var errorTitle: ToastState { ToastState(title: "错误") }

    static var successTitle: ToastState { ToastState(title: "成功") }

    static var loadingTitle: ToastState { ToastState(title: "加载中") }

    mutating func show(title: String? = nil, message: String) {
        if let title = title {
            self.title = title
        }
        self.message = message
        self.isPresenting = true
    }

    mutating func hide() {
        self.isPresenting = false
    }
}

extension View {
    func errorToast(isPresenting: Binding<Bool>, title: String, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(type: .error(.red), title: title, subTitle: message)
        }
    }

    func warningToast(isPresenting: Binding<Bool>, title: String, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(displayMode: .banner(.slide), type: .systemImage("exclamationmark.triangle", .yellow), title: title, subTitle: message)
        }
    }

    func successToast(isPresenting: Binding<Bool>, title: String, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(type: .complete(.green), title: title, subTitle: message)
        }
    }

    func loadingToast(isPresenting: Binding<Bool>, title: String, message: String) -> some View {
        toast(isPresenting: isPresenting) {
            AlertToast(type: .loading, title: title, subTitle: message)
        }
    }

    func errorToast(_ state: Binding<ToastState>) -> some View {
        errorToast(isPresenting: state.isPresenting, title: state.wrappedValue.title, message: state.wrappedValue.message)
    }

    func warningToast(_ state: Binding<ToastState>) -> some View {
        warningToast(isPresenting: state.isPresenting, title: state.wrappedValue.title, message: state.wrappedValue.message)
    }

    func successToast(_ state: Binding<ToastState>) -> some View {
        successToast(isPresenting: state.isPresenting, title: state.wrappedValue.title, message: state.wrappedValue.message)
    }

    func loadingToast(_ state: Binding<ToastState>) -> some View {
        loadingToast(isPresenting: state.isPresenting, title: state.wrappedValue.title, message: state.wrappedValue.message)
    }
}
