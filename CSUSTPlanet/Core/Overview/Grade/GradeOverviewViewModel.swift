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

    init() {
        MMKVHelper.shared.$courseGradesCache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.gradeAnalysisData = data
            }
            .store(in: &cancellables)
    }

    var gradeAnalysis: GradeAnalysisData? {
        guard let courseGrades = gradeAnalysisData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }
}
