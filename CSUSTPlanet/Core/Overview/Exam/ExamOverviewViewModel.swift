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

    @ObservationIgnored var isFirstObservation = true
    var isLoadingExams: Bool = false

    var pendingExams: [EduHelper.Exam] {
        guard let examData = examScheduleData?.value else { return [] }
        return examData.filter { .now <= $0.examEndTime }
    }

    var cachedAt: Date? {
        examScheduleData?.cachedAt
    }

    init() {
        MMKVHelper.shared.$examSchedulesCache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if isFirstObservation {
                    self.examScheduleData = data
                    isFirstObservation = false
                } else {
                    withAnimation {
                        self.examScheduleData = data
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadExams() async {
        guard !isLoadingExams else { return }
        isLoadingExams = true
        defer { isLoadingExams = false }

        do {
            let exams = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.examService.getExamSchedule(academicYearSemester: nil, semesterType: nil)
            }
            let sortedExams = exams.sorted {
                return $0.examStartTime < $1.examStartTime
            }

            MMKVHelper.shared.examSchedulesCache = Cached<[EduHelper.Exam]>(cachedAt: .now, value: sortedExams)
        } catch {}
    }

    func daysUntilExam(_ exam: EduHelper.Exam) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: exam.examStartTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: examDay)
        return components.day ?? 0
    }
}
