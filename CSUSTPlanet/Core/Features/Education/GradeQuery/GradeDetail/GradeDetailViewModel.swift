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
            if let eduHelper = AuthManager.shared.eduHelper {
                let maxRetryCount = 3
                var lastError: Error?

                for _ in 1...maxRetryCount {
                    do {
                        gradeDetail = try await eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
                        return
                    } catch {
                        lastError = error
                    }
                }

                let retryHint = "获取成绩详情失败，请点击右上角刷新后重试"
                if let lastError {
                    errorMessage = "\(retryHint)\n\(lastError.localizedDescription)"
                } else {
                    errorMessage = retryHint
                }
                isShowingError = true
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = "请先登录教务系统后再查询数据"
                    self.isShowingWarning = true
                }
            }
        }
    }
}
