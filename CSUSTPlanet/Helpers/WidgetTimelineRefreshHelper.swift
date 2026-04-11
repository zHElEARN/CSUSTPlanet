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
    private static let todayCoursesWidgetKind = "TodayCoursesWidget"
    private static let weeklyCoursesWidgetKind = "WeeklyCoursesWidget"
    private static let dormElectricityWidgetKind = "DormElectricityWidget"

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

    static func reloadCourseScheduleWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: todayCoursesWidgetKind)
        WidgetCenter.shared.reloadTimelines(ofKind: weeklyCoursesWidgetKind)
        #endif
    }

    static func reloadDormElectricity() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: dormElectricityWidgetKind)
        #endif
    }
}
