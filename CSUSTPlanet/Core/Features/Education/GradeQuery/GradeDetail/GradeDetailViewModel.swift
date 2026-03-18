//
//  GradeDetailViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
class GradeDetailViewModel {
    enum GradeRenderMode: String, CaseIterable, Identifiable {
        case pie = "饼图"
        case progress = "进度条"
        var id: String { rawValue }
    }

    var gradeRenderMode: GradeRenderMode = .progress

    var gradeDetail: EduHelper.GradeDetail?
    var errorMessage: String = ""
    var warningMessage: String = ""

    var isLoading = false
    var isShowingError = false
    var isShowingWarning = false

    func task(_ courseGrade: EduHelper.CourseGrade) {
        loadDetail(courseGrade)
    }

    func loadDetail(_ courseGrade: EduHelper.CourseGrade) {
        isLoading = true

        Task {
            defer {
                isLoading = false
            }
            let maxRetryCount = 3

            for _ in 1...maxRetryCount {
                do {
                    gradeDetail = try await AuthManager.shared.eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
                    return
                }
            }

            errorMessage = "获取成绩详情失败，请点击右上角刷新后重试"
            isShowingError = true
        }
    }
}
