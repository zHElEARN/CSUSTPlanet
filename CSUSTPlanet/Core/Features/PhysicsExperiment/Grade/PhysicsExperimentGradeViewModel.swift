//
//  PhysicsExperimentGradeViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/4.
//

import CSUSTKit
import Foundation

@MainActor
@Observable
final class PhysicsExperimentGradeViewModel: Observable {
    var data: [PhysicsExperimentHelper.CourseGrade] = []

    var isLoadingGrades = false
    var errorToast: ToastState = .errorTitle

    var isInitial = true

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadGrades()
    }

    func loadGrades() async {
        guard !isLoadingGrades else { return }
        isLoadingGrades = true
        defer { isLoadingGrades = false }

        do {
            self.data = try await PhysicsExperimentManager.shared.getCourseGrades()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
