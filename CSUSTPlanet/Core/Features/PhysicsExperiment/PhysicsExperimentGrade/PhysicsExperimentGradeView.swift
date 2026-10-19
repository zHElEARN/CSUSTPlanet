//
//  PhysicsExperimentGradeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/11/3.
//

import CSUSTKit
import SwiftUI

struct PhysicsExperimentGradeView: View {
    @State private var grades: [PhysicsExperimentHelper.CourseGrade]?

    @State private var isLoadingGrades = false

    @State private var errorToast: ToastState = .errorTitle

    @State private var isLoginPresented = false

    @State private var isInitial = true

    var body: some View {
        PhysicsExperimentGradeContent(
            grades: grades,
            isLoadingGrades: isLoadingGrades,
            isLoginPresented: $isLoginPresented,
            errorToast: $errorToast,
            onRefreshGrades: loadGrades
        )
        .onChange(of: isLoginPresented) { _, newValue in
            if !newValue { Task { await loadGrades() } }
        }
        .task {
            guard isInitial else { return }
            isInitial = false
            await loadGrades()
        }
    }

    // MARK: - Methods

    private func loadGrades() async {
        guard !isLoadingGrades else { return }
        isLoadingGrades = true
        defer { isLoadingGrades = false }

        do {
            grades = try await PhysicsExperimentManager.shared.getCourseGrades()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
