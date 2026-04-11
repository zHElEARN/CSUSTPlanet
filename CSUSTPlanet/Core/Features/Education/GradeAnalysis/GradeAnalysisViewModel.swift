//
//  GradeAnalysisViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/12.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
@Observable
class GradeAnalysisViewModel: NSObject {
    enum ChartType: String, CaseIterable {
        case averageGrade = "平均成绩"
        case gpa = "GPA"
    }

    enum DistributionChartType: String, CaseIterable {
        case gradePoint = "绩点"
        case gradeRange = "成绩"
    }

    // 绩点到成绩段的映射
    static let gradePointToRangeMap: [Double: String] = {
        var map: [Double: String] = [:]
        for range in ColorUtil.gradeRanges {
            map[range.point] = range.range
        }
        return map
    }()

    var courseGradesData: Cached<[EduHelper.CourseGrade]>?
    var weightedAverageGrade: Double?
    var selectedChartType: ChartType = .averageGrade
    var selectedDistributionChartType: DistributionChartType = .gradePoint

    var isLoadingAnalysis: Bool = false
    var isShowingShareSheet: Bool = false

    var errorToast: ToastState = .errorTitle
    var successToast: ToastState = .successTitle

    var analysisData: GradeAnalysisData? {
        guard let courseGrades = courseGradesData?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    var shareContent: Any?

    var isInitial: Bool = true

    override init() {
        super.init()
        guard let data = MMKVHelper.CourseGrades.cache else { return }
        self.courseGradesData = data
    }

    func loadInitial() async {
        guard isInitial else { return }
        isInitial = false
        await loadGradeAnalysis()
    }

    func loadGradeAnalysis() async {
        guard !isLoadingAnalysis else { return }
        isLoadingAnalysis = true
        defer { isLoadingAnalysis = false }

        do {
            let courseGrades = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.courseService.getCourseGrades()
            }
            let data = Cached(cachedAt: .now, value: courseGrades)
            self.courseGradesData = data
            MMKVHelper.CourseGrades.cache = data
            WidgetTimelineRefreshHelper.reloadGradeAnalysis()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    #if os(iOS)
    func showShareSheet(_ shareableView: some View) {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage else {
            errorToast.show(message: "生成图片失败")
            return
        }
        shareContent = ImageActivityItemSource(title: "我的成绩分析", image: uiImage)
        isShowingShareSheet = true
    }

    func saveToPhotoAlbum(_ shareableView: some View) {
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(saveToPhotoAlbumCallback(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            errorToast.show(message: "生成图片失败")
        }
    }

    @objc
    func saveToPhotoAlbumCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            errorToast.show(message: "保存图片失败，可能是没有权限: \(error.localizedDescription)")
        } else {
            successToast.show(message: "图片保存成功")
        }
    }
    #endif
}
