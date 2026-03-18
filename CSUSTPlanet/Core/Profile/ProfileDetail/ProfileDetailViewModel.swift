//
//  ProfileViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
class ProfileDetailViewModel {
    var ssoProfile: SSOHelper.Profile?
    var isSSOProfileLoading: Bool = false

    var eduProfile: EduHelper.Profile?
    var isEduProfileLoading: Bool = false

    var moocProfile: MoocHelper.Profile?
    var isMoocProfileLoading: Bool = false

    var isShowingError: Bool = false
    var errorMessage: String = ""

    func loadSSOProfile() {
        isSSOProfileLoading = true
        Task {
            defer {
                isSSOProfileLoading = false
            }

            do {
                ssoProfile = try await AuthManager.shared.ssoHelper.getLoginUser()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadEduProfile() {
        isEduProfileLoading = true
        Task {
            defer {
                isEduProfileLoading = false
            }

            do {
                eduProfile = try await AuthManager.shared.eduHelper.profileService.getProfile()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

    func loadMoocProfile() {
        isMoocProfileLoading = true
        Task {
            defer {
                isMoocProfileLoading = false
            }

            do {
                moocProfile = try await AuthManager.shared.moocHelper.getProfile()
            } catch {
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }
}
