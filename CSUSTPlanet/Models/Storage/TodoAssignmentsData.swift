//
//  TodoAssignmentsData.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import Foundation

struct TodoAssignmentsData: Codable {
    var course: MoocHelper.Course
    var assignments: [MoocHelper.Assignment]
}
