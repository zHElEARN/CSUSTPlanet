//
//  AssignmentsData.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/20.
//

import CSUSTKit
import Foundation

struct AssignmentsData: Codable {
    var course: MoocHelper.Course
    var assignments: [MoocHelper.Assignment]
}
