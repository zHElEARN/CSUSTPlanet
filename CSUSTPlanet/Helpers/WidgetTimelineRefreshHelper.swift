//
//  WidgetTimelineRefreshHelper.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/4/11.
//

#if canImport(WidgetKit)
import WidgetKit
#endif

enum WidgetTimelineRefreshHelper {
    private static let todoAssignmentsWidgetKind = "TodoAssignmentsWidget"
    private static let gradeAnalysisWidgetKind = "GradeAnalysisWidget"

    static func reloadTodoAssignments() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: todoAssignmentsWidgetKind)
        #endif
    }

    static func reloadGradeAnalysis() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: gradeAnalysisWidgetKind)
        #endif
    }
}
