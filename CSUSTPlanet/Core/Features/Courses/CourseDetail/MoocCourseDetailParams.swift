//
//  MoocCourseDetailParams.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/19.
//

import CSUSTKit

struct MoocCourseDetailParams: Hashable {
    let id: String
    let name: String
    let number: String?
    let department: String?
    let teacher: String?

    init(course: MoocHelper.Course) {
        id = course.id
        name = course.name
        number = course.number
        department = course.department
        teacher = course.teacher
    }

    var course: MoocHelper.Course {
        MoocHelper.Course(id: id, name: name, number: number, department: department, teacher: teacher)
    }
}
