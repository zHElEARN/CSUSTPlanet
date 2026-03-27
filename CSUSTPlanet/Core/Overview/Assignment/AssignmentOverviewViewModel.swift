//
//  AssignmentOverviewViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/9/5.
//

import CSUSTKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class AssignmentOverviewViewModel {
    private var todoAssignmentsData: Cached<[TodoAssignmentsData]>?

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

    func onAppear() {
        todoAssignmentsData = MMKVHelper.TodoAssignments.cache
    }
}
