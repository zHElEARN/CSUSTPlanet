//
//  TodoAssignmentsEntry.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/27.
//

import CSUSTKit
import WidgetKit

struct TodoAssignmentsEntry: TimelineEntry {
    let date: Date
    let data: [TodoAssignmentsData]?
    let lastUpdated: Date?

    static func mockEntry(
        scenario: MockScenario = .assignments(7),
        lastUpdated: Date = .now.addingTimeInterval(-1800)
    ) -> TodoAssignmentsEntry {
        TodoAssignmentsEntry(
            date: .now,
            data: mockData(for: scenario),
            lastUpdated: scenario == .emptyData ? nil : lastUpdated
        )
    }
}

extension TodoAssignmentsEntry {
    enum MockScenario: Equatable {
        case emptyData
        case emptyAssignments
        case assignments(Int)
    }

    private struct MockAssignmentSeed {
        let course: MoocHelper.Course
        let assignment: MoocHelper.Assignment
    }

    private static func mockData(for scenario: MockScenario) -> [TodoAssignmentsData]? {
        switch scenario {
        case .emptyData:
            return nil
        case .emptyAssignments:
            return buildGroupedData(from: expiredSeeds)
        case .assignments(let count):
            return buildGroupedData(from: Array(activeSeeds.prefix(max(0, count))))
        }
    }

    private static func buildGroupedData(from seeds: [MockAssignmentSeed]) -> [TodoAssignmentsData] {
        var groupedAssignments: [String: [MoocHelper.Assignment]] = [:]
        var coursesByID: [String: MoocHelper.Course] = [:]
        var orderedCourseIDs: [String] = []

        for seed in seeds {
            if coursesByID[seed.course.id] == nil {
                coursesByID[seed.course.id] = seed.course
                orderedCourseIDs.append(seed.course.id)
            }
            groupedAssignments[seed.course.id, default: []].append(seed.assignment)
        }

        return orderedCourseIDs.compactMap { courseID in
            guard let course = coursesByID[courseID], let assignments = groupedAssignments[courseID] else { return nil }
            return TodoAssignmentsData(course: course, assignments: assignments)
        }
    }

    private static let algorithmsCourse = MoocHelper.Course(
        id: "course-1",
        name: "程序设计、算法与数据结构（三）",
        number: "CS101",
        department: "计算机学院",
        teacher: "张老师"
    )

    private static let physicsCourse = MoocHelper.Course(
        id: "course-2",
        name: "大学物理B（下）",
        number: "PH201",
        department: "理学院",
        teacher: "李老师"
    )

    private static let ideologyCourse = MoocHelper.Course(
        id: "course-3",
        name: "马克思主义基本原理",
        number: "POL101",
        department: "马克思主义学院",
        teacher: "王老师"
    )

    private static let experimentCourse = MoocHelper.Course(
        id: "course-4",
        name: "大学物理实验B",
        number: "PH203",
        department: "理学院",
        teacher: "周老师"
    )

    private static let activeSeeds: [MockAssignmentSeed] = [
        .init(
            course: algorithmsCourse,
            assignment: .init(
                id: 1,
                title: "实验五：图算法实现",
                publisher: "张老师",
                canSubmit: true,
                submitStatus: false,
                deadline: .now.addingTimeInterval(2 * 3600),
                startTime: .now.addingTimeInterval(-2 * 24 * 3600)
            )
        ),
        .init(
            course: physicsCourse,
            assignment: .init(
                id: 2,
                title: "第六章课后习题",
                publisher: "李老师",
                canSubmit: true,
                submitStatus: false,
                deadline: .now.addingTimeInterval(8 * 3600),
                startTime: .now.addingTimeInterval(-24 * 3600)
            )
        ),
        .init(
            course: ideologyCourse,
            assignment: .init(
                id: 3,
                title: "专题讨论报告",
                publisher: "王老师",
                canSubmit: true,
                submitStatus: false,
                deadline: .now.addingTimeInterval(18 * 3600),
                startTime: .now.addingTimeInterval(-3 * 24 * 3600)
            )
        ),
        .init(
            course: algorithmsCourse,
            assignment: .init(
                id: 4,
                title: "OJ 周测 08",
                publisher: "张老师",
                canSubmit: true,
                submitStatus: false,
                deadline: .now.addingTimeInterval(30 * 3600),
                startTime: .now.addingTimeInterval(-3 * 24 * 3600)
            )
        ),
        .init(
            course: experimentCourse,
            assignment: .init(
                id: 5,
                title: "实验报告七",
                publisher: "周老师",
                canSubmit: true,
                submitStatus: false,
                deadline: .now.addingTimeInterval(40 * 3600),
                startTime: .now.addingTimeInterval(-2 * 24 * 3600)
            )
        ),
        .init(
            course: physicsCourse,
            assignment: .init(
                id: 6,
                title: "随堂测试 3",
                publisher: "李老师",
                canSubmit: false,
                submitStatus: false,
                deadline: .now.addingTimeInterval(52 * 3600),
                startTime: .now.addingTimeInterval(-12 * 3600)
            )
        ),
        .init(
            course: ideologyCourse,
            assignment: .init(
                id: 7,
                title: "阅读心得整理",
                publisher: "王老师",
                canSubmit: true,
                submitStatus: false,
                deadline: .now.addingTimeInterval(64 * 3600),
                startTime: .now.addingTimeInterval(-5 * 24 * 3600)
            )
        ),
        .init(
            course: algorithmsCourse,
            assignment: .init(
                id: 8,
                title: "课堂讨论记录",
                publisher: "张老师",
                canSubmit: true,
                submitStatus: true,
                deadline: .now.addingTimeInterval(80 * 3600),
                startTime: .now.addingTimeInterval(-4 * 24 * 3600)
            )
        ),
    ]

    private static let expiredSeeds: [MockAssignmentSeed] = [
        .init(
            course: algorithmsCourse,
            assignment: .init(
                id: 101,
                title: "已截止练习",
                publisher: "张老师",
                canSubmit: false,
                submitStatus: false,
                deadline: .now.addingTimeInterval(-2 * 3600),
                startTime: .now.addingTimeInterval(-2 * 24 * 3600)
            )
        ),
        .init(
            course: physicsCourse,
            assignment: .init(
                id: 102,
                title: "已截止实验报告",
                publisher: "李老师",
                canSubmit: false,
                submitStatus: true,
                deadline: .now.addingTimeInterval(-26 * 3600),
                startTime: .now.addingTimeInterval(-4 * 24 * 3600)
            )
        ),
    ]
}
