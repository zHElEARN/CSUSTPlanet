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

    var isLoading = false

    var errorState = ToastState()

    var refreshTrigger = false

    func triggerRefresh() {
        refreshTrigger.toggle()
    }

    func loadDetail(_ courseGrade: EduHelper.CourseGrade) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let maxRetryCount = 3
        for _ in 1...maxRetryCount {
            if let gradeDetail = try? await AuthManager.shared.eduHelper.courseService.getGradeDetail(url: courseGrade.gradeDetailUrl) {
                self.gradeDetail = gradeDetail
                return
            }
        }

        errorState.show(message: "获取成绩详情失败，请刷新重试")
    }
}
