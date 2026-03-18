//
//  View+Toast.swift
//  CSUSTPlanet
//
//  Created by Claude on 2026/3/18.
//

import AlertToast
import SwiftUI

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
}
