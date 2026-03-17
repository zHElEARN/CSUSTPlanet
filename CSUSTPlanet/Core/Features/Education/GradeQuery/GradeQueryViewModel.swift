//
//  GradeQueryViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

@MainActor
@Observable
class GradeQueryViewModel {
    struct SelectionItem: Hashable {
        let course: String
    }

    // MARK: States

    var data: Cached<[EduHelper.CourseGrade]>? = nil
    var analysis: GradeAnalysisData? = nil
    var searchText: String = "" {
        didSet { updateFilteredGrades() }
    }
    var errorMessage: String = ""
    var warningMessage: String = ""

    var isLoading: Bool = false
    var isShowingShareSheet: Bool = false
    var isShowingError: Bool = false
    var isShowingWarning: Bool = false

    var isSelectionMode: Bool = false {
        didSet { updateAnalysis() }
    }

    var selectedItems = Set<SelectionItem>() {
        didSet { if isSelectionMode { updateAnalysis() } }
    }

    var expandedSemesters: Set<String> = []

    var semesterGPAs: [String: Double] = [:]

    var shareContent: Any? = nil
    var isLoaded: Bool = false

    private(set) var filteredCourseGrades: [EduHelper.CourseGrade] = []
    private(set) var groupedFilteredCourseGrades: [(semester: String, grades: [EduHelper.CourseGrade])] = []

    // MARK: - Methods

    init() {
        guard let data = MMKVHelper.shared.courseGradesCache else { return }
        applyData(data)
    }

    func task() {
        guard !isLoaded else { return }
        isLoaded = true
        loadCourseGrades()
    }

    func loadCourseGrades() {
        isLoading = true
        Task {
            defer {
                isLoading = false
            }
            if let eduHelper = AuthManager.shared.eduHelper {
                do {
                    let courseGrades = try await eduHelper.courseService.getCourseGrades(academicYearSemester: nil, courseNature: nil, courseName: "")
                    let data = Cached(cachedAt: .now, value: courseGrades)
                    applyData(data)
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
                applyData(data)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.warningMessage = String(format: "教务系统未登录，\n已加载上次查询数据（%@）", DateUtil.relativeTimeString(for: data.cachedAt))
                    self.isShowingWarning = true
                }
            }
        }
    }

    // MARK: - Expand Semesters

    func toggleExpandSemester(_ semester: String) {
        withAnimation {
            if expandedSemesters.contains(semester) {
                expandedSemesters.remove(semester)
            } else {
                expandedSemesters.insert(semester)
            }
        }
    }

    func bindingForSemester(_ semester: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { [weak self] in
                self?.expandedSemesters.contains(semester) ?? false
            },
            set: { [weak self] newValue in
                if newValue {
                    self?.expandedSemesters.insert(semester)
                } else {
                    self?.expandedSemesters.remove(semester)
                }
            }
        )
    }

    // MARK: - Selection Mode

    func enterSelectionMode() {
        selectedItems = Set(filteredCourseGrades.map { SelectionItem(course: $0.courseID) })
        isSelectionMode = true
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedItems.removeAll()
    }

    func selectAll() {
        selectedItems = Set(filteredCourseGrades.map { SelectionItem(course: $0.courseID) })
    }

    func selectNone() {
        selectedItems.removeAll()
    }

    func toggleSelection(for courseID: String) {
        let item = SelectionItem(course: courseID)
        withAnimation {
            if selectedItems.contains(item) {
                selectedItems.remove(item)
            } else {
                selectedItems.insert(item)
            }
        }
    }

    func isSelected(_ courseID: String) -> Bool {
        selectedItems.contains(SelectionItem(course: courseID))
    }

    private func applyData(_ data: Cached<[EduHelper.CourseGrade]>) {
        self.data = data
        self.expandedSemesters = Set(data.value.map { $0.semester })
        self.semesterGPAs = computeSemesterGPAs(data.value)
        updateFilteredGrades()
        updateAnalysis()
    }

    private func computeSemesterGPAs(_ grades: [EduHelper.CourseGrade]) -> [String: Double] {
        Dictionary(grouping: grades, by: { $0.semester }).reduce(into: [:]) { result, entry in
            let totalCredits = entry.value.reduce(0) { $0 + $1.credit }
            let totalGradePoints = entry.value.reduce(0) { $0 + $1.gradePoint * $1.credit }
            result[entry.key] = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0
        }
    }

    private func updateFilteredGrades() {
        guard let data = data else {
            filteredCourseGrades = []
            groupedFilteredCourseGrades = []
            return
        }
        let filtered: [EduHelper.CourseGrade]
        if searchText.isEmpty {
            filtered = data.value
        } else {
            filtered = data.value.filter { $0.courseName.localizedCaseInsensitiveContains(searchText) }
        }
        filteredCourseGrades = filtered
        let grouped = Dictionary(grouping: filtered) { $0.semester }
        groupedFilteredCourseGrades = grouped.keys.sorted(by: >).map { (semester: $0, grades: grouped[$0] ?? []) }
    }

    private func updateAnalysis() {
        guard let allCourses = data?.value else {
            analysis = nil
            return
        }

        let coursesToAnalyze: [EduHelper.CourseGrade]

        if isSelectionMode {
            coursesToAnalyze = allCourses.filter { selectedItems.contains(SelectionItem(course: $0.courseID)) }
        } else {
            coursesToAnalyze = allCourses
        }

        analysis = GradeAnalysisData.fromCourseGrades(coursesToAnalyze)
    }

    // MARK: - CSV Export

    func exportGradesAsCSV() {
        guard let csvString = generateCSVString(from: filteredCourseGrades) else {
            errorMessage = "没有可导出的成绩数据"
            isShowingError = true
            return
        }

        guard let csvData = csvString.data(using: .utf8) else {
            errorMessage = "无法将CSV数据编码为UTF-8"
            isShowingError = true
            return
        }

        #if os(iOS)
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileName = "成绩导出-\(Date().formatted(date: .numeric, time: .shortened)).csv"
        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "-")
        let fileURL = temporaryDirectory.appendingPathComponent(sanitizedFileName)

        do {
            try csvData.write(to: fileURL)

            shareContent = fileURL
            isShowingShareSheet = true

        } catch {
            errorMessage = "无法保存临时的CSV文件: \(error.localizedDescription)"
            isShowingError = true
        }
        #elseif os(macOS)
        let savePanel = NSSavePanel()
        savePanel.title = "导出成绩表格"
        savePanel.nameFieldStringValue = "成绩导出-\(Date().formatted(date: .numeric, time: .shortened)).csv"
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            do {
                try csvData.write(to: url)
            } catch {
                Task { @MainActor in
                    self.errorMessage = "无法保存CSV文件: \(error.localizedDescription)"
                    self.isShowingError = true
                }
            }
        }
        #endif
    }

    private func generateCSVString(from courseGrades: [EduHelper.CourseGrade]) -> String? {
        guard !courseGrades.isEmpty else { return nil }
        let header = "开课学期,课程编号,课程名称,分组名,成绩,详细成绩链接,修读方式,成绩标识,学分,总学时,绩点,补重学期,考核方式,考试性质,课程属性,课程性质,课程类别\n"

        let rows = courseGrades.map { grade -> String in
            let semester = escapeCSVField(grade.semester)
            let courseID = escapeCSVField(grade.courseID)
            let courseName = escapeCSVField(grade.courseName)
            let groupName = escapeCSVField(grade.groupName)
            let gradeValue = "\(grade.grade)"
            let gradeDetailUrl = escapeCSVField(grade.gradeDetailUrl)
            let studyMode = escapeCSVField(grade.studyMode)
            let gradeIdentifier = escapeCSVField(grade.gradeIdentifier)
            let credit = "\(grade.credit)"
            let totalHours = "\(grade.totalHours)"
            let gradePoint = "\(grade.gradePoint)"
            let retakeSemester = escapeCSVField(grade.retakeSemester)
            let assessmentMethod = escapeCSVField(grade.assessmentMethod)
            let examNature = escapeCSVField(grade.examNature)
            let courseAttribute = escapeCSVField(grade.courseAttribute)
            let courseNature = escapeCSVField(grade.courseNature.rawValue)
            let courseCategory = escapeCSVField(grade.courseCategory)

            return [semester, courseID, courseName, groupName, gradeValue, gradeDetailUrl, studyMode, gradeIdentifier, credit, totalHours, gradePoint, retakeSemester, assessmentMethod, examNature, courseAttribute, courseNature, courseCategory].joined(separator: ",")
        }

        return header + rows.joined(separator: "\n")
    }

    private func escapeCSVField(_ field: String) -> String {
        var escapedField = field
        escapedField = escapedField.replacingOccurrences(of: "\"", with: "\"\"")
        if escapedField.contains(",") || escapedField.contains("\"") {
            escapedField = "\"\(escapedField)\""
        }
        return escapedField
    }
}
