//
//  GradeAnalysisView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import SwiftUI

struct GradeAnalysisView: View {
    @State private var courseGradesData: Cached<[EduHelper.CourseGrade]>? = MMKVHelper.CourseGrades.cache

    @State private var isLoadingAnalysis: Bool = false

    @State private var errorToast: ToastState = .errorTitle
    @State private var successToast: ToastState = .successTitle

    @State private var isInitial: Bool = true

    private var analysisData: GradeAnalysisData? {
        guard let courseGrades = courseGradesData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    private var canShare: Bool {
        !(courseGradesData?.value.isEmpty ?? false)
    }

    // MARK: - Body

    var body: some View {
        GradeAnalysisContent(
            analysisData: analysisData,
            canShare: canShare,
            isLoading: isLoadingAnalysis,
            errorToast: $errorToast,
            successToast: $successToast,
            onRefresh: loadGradeAnalysis
        )
        .onReceive(MMKVHelper.CourseGrades.$cache.dropFirst().receive(on: RunLoop.main)) { cachedData in
            courseGradesData = cachedData
        }
        .task {
            guard isInitial else { return }
            isInitial = false
            await loadGradeAnalysis()
        }
    }

    // MARK: - Methods

    private func loadGradeAnalysis() async {
        guard !isLoadingAnalysis else { return }
        isLoadingAnalysis = true
        defer { isLoadingAnalysis = false }

        do {
            let courseGrades = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseGrades()
            }
            let data = Cached(cachedAt: .now, value: courseGrades)
            MMKVHelper.CourseGrades.cache = data
            WidgetTimelineRefreshHelper.reloadGradeAnalysis()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
