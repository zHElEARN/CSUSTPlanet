//
//  GradeOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class GradeOverviewViewModel {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?

    @ObservationIgnored var isFirstObservation = true
    var isLoadingGrades: Bool = false

    var cachedAt: Date? {
        gradeAnalysisData?.cachedAt
    }

    init() {
        MMKVHelper.shared.$courseGradesCache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if isFirstObservation {
                    self.gradeAnalysisData = data
                    isFirstObservation = false
                } else {
                    withAnimation {
                        self.gradeAnalysisData = data
                    }
                }
            }
            .store(in: &cancellables)
    }

    var gradeAnalysis: GradeAnalysisData? {
        guard let courseGrades = gradeAnalysisData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    func loadGrades() async {
        guard !isLoadingGrades else { return }
        isLoadingGrades = true
        defer { isLoadingGrades = false }

        do {
            let courseGrades = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseGrades(academicYearSemester: nil, courseNature: nil, courseName: "")
            }
            MMKVHelper.shared.courseGradesCache = Cached(cachedAt: .now, value: courseGrades)
        } catch {}
    }
}
