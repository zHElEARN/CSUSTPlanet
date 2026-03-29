//
//  AssignmentOverviewViewModel.swift
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
final class AssignmentOverviewViewModel {
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var todoAssignmentsData: Cached<[TodoAssignmentsData]>?

    init() {
        MMKVHelper.TodoAssignments.$cache
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.todoAssignmentsData = data
            }
            .store(in: &cancellables)
    }

    var submittableAssignments: [(courseName: String, assignment: MoocHelper.Assignment)] {
        guard let groups = todoAssignmentsData?.value else { return [] }

        return
            groups
            .flatMap { group in
                group.assignments.compactMap { assignment in
                    guard assignment.canSubmit, !assignment.submitStatus else { return nil }
                    return (courseName: group.course.name, assignment: assignment)
                }
            }
            .sorted { $0.assignment.deadline < $1.assignment.deadline }
    }
}
