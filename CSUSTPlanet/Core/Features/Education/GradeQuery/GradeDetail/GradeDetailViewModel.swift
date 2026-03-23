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

    var renderMode: GradeRenderMode = .progress

    var detail: EduHelper.GradeDetail?

    var isLoadingDetail = false

    var errorToast: ToastState = .errorTitle

    func loadDetail(_ courseGrade: EduHelper.CourseGrade) async {
        guard !isLoadingDetail else { return }
        isLoadingDetail = true
        defer { isLoadingDetail = false }

        let maxRetryCount = 5

        for _ in 1...maxRetryCount {
            do {
                let gradeDetail = try await AuthManager.shared.withAuthRetry(system: .edu) {
                    try await AuthManager.shared.eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl)
                }

                self.detail = gradeDetail
                return
            } catch {}
        }

        let errorMessage = "获取成绩详情失败，请刷新重试"
        errorToast.show(message: errorMessage)
    }
}
