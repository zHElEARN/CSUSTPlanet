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

    var errorMessage: String = ""
    var warningMessage: String = ""
    var data: Cached<[EduHelper.CourseGrade]>?
    var weightedAverageGrade: Double?
    var selectedChartType: ChartType = .averageGrade
    var selectedDistributionChartType: DistributionChartType = .gradePoint

    var isLoading: Bool = false
    var isShowingWarning: Bool = false
    var isShowingError: Bool = false
    var isShowingSuccess: Bool = false
    var isShowingShareSheet: Bool = false

    var analysisData: GradeAnalysisData? {
        guard let courseGrades = data?.value else { return nil }
        return GradeAnalysisData.fromCourseGrades(courseGrades)
    }

    var shareContent: Any?

    override init() {
        super.init()
        guard let data = MMKVHelper.shared.courseGradesCache else { return }
        self.data = data
    }

    func task() {
        loadGradeAnalysis()
    }

    func loadGradeAnalysis() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }

            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courseGrades = try await eduHelper.courseService.getCourseGrades()
                    let data = Cached(cachedAt: .now, value: courseGrades)
                    self.data = data
                    MMKVHelper.shared.courseGradesCache = data
                    WidgetCenter.shared.reloadTimelines(ofKind: "GradeAnalysisWidget")
                } catch {
                    errorMessage = error.localizedDescription
                    isShowingError = true
                }
            } else {
                guard let data = MMKVHelper.shared.courseGradesCache else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.warningMessage = "请先登录教务系统后再查询数据"
                        self.isShowingWarning = true
                    }
                    return
                }
                self.data = data
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
            }
        }
    }

    func showShareSheet(_ shareableView: some View) {
        #if os(iOS)
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage else {
            errorMessage = "生成图片失败"
            isShowingError = true
            return
        }
        shareContent = ImageActivityItemSource(title: "我的成绩分析", image: uiImage)
        #endif
        isShowingShareSheet = true
    }

    func saveToPhotoAlbum(_ shareableView: some View) {
        #if os(iOS)
        let renderer = ImageRenderer(content: shareableView)
        renderer.scale = UIScreen.main.scale
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(saveToPhotoAlbumCallback(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            errorMessage = "生成图片失败"
            isShowingError = true
        }
        #endif
    }

    #if os(iOS)
    @objc
    func saveToPhotoAlbumCallback(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            errorMessage = "保存图片失败，可能是没有权限: \(error.localizedDescription)"
            isShowingError = true
        } else {
            isShowingSuccess = true
        }
    }
    #endif
}
