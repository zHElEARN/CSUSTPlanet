//
//  CSUSTPlanetWidgetBundle.swift
//  CSUSTPlanetWidget
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import SwiftUI
import WidgetKit

@main
struct CSUSTPlanetWidgetBundle: WidgetBundle {
    var body: some Widget {
        DormElectricityWidget()
        GradeAnalysisWidget()
        TodayCoursesWidget()
        WeeklyCoursesWidget()
        // UrgentCoursesWidget()

        #if os(iOS)
        CourseStatusWidgetLiveActivity()
        #endif
    }
}
