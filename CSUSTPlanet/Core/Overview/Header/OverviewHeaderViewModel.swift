//
//  OverviewHeaderViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class OverviewHeaderViewModel {
    private var courseScheduleData: Cached<CourseScheduleData>?

    var weekInfo: String? {
        guard let data = courseScheduleData?.value else { return nil }
        let semester = data.semester ?? "默认学期"

        if let currentWeek = CourseScheduleUtil.getCurrentWeek(semesterStartDate: data.semesterStartDate, now: .now) {
            return "\(semester) 第\(currentWeek)周"
        }
        return semester
    }

    func onAppear() {
        courseScheduleData = MMKVHelper.shared.courseScheduleCache
    }
}
