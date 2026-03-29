//
//  ExamOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Combine
import Foundation
import SwiftUI

@MainActor
@Observable
final class ExamOverviewViewModel {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var examScheduleData: Cached<[EduHelper.Exam]>?

    init() {
        MMKVHelper.shared.$examSchedulesCache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.examScheduleData = data
            }
            .store(in: &cancellables)
    }

    var pendingExams: [EduHelper.Exam] {
        guard let examData = examScheduleData?.value else { return [] }
        return examData.filter { .now <= $0.examEndTime }
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }
}
