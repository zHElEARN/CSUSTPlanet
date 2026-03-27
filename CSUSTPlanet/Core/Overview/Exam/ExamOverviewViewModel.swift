//
//  ExamOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class ExamOverviewViewModel {
    private var examScheduleData: Cached<[EduHelper.Exam]>?

    var pendingExams: [EduHelper.Exam] {
        guard let examData = examScheduleData?.value else { return [] }
        return examData.filter { .now <= $0.examEndTime }
    }

    func onAppear() {
        examScheduleData = MMKVHelper.shared.examSchedulesCache
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }
}
