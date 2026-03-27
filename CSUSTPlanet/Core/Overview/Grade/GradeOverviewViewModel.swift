//
//  GradeOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class GradeOverviewViewModel {
    private var gradeAnalysisData: Cached<[EduHelper.CourseGrade]>?

    var gradeAnalysis: GradeAnalysisData? {
        guard let courseGrades = gradeAnalysisData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    func onAppear() {
        gradeAnalysisData = MMKVHelper.shared.courseGradesCache
    }
}
