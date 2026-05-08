//
//  PhysicsExperimentLoginViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class PhysicsExperimentLoginViewModel {
    var username: String = KeychainUtil.physicsExperimentUsername ?? ""
    var password: String = KeychainUtil.physicsExperimentPassword ?? ""
    var isPasswordVisible: Bool = false
    var errorToast: ToastState = .errorTitle

    var isLoginDisabled: Bool {
        username.isEmpty || password.isEmpty || PhysicsExperimentManager.shared.isLoggingIn
    }

    func login(_ done: () -> Void) async {
        guard !username.isEmpty, !password.isEmpty else {
            errorToast.show(message: "请输入用户名和密码")
            return
        }

        do {
            try await PhysicsExperimentManager.shared.login(username: username, password: password)
            done()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
