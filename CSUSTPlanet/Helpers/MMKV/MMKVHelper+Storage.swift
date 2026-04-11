//
//  MMKVHelper+Storage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/11.
//

import CSUSTKit

extension MMKVHelper {
    enum TodoAssignments {
        @MMKVOptionalStorage(key: "TodoAssignments.cache")
        static var cache: Cached<[TodoAssignmentsData]>?
    }

    enum SwiftData {
        @MMKVStorage(key: "SwiftData.databaseVersion", defaultValue: 0)
        static var databaseVersion: Int

        @MMKVStorage(key: "SwiftData.hasMigratedToGRDB", defaultValue: false)
        static var hasMigratedToGRDB: Bool
    }

    enum CourseGrades {
        @MMKVOptionalStorage(key: "Cached.courseGradesCache")
        static var cache: Cached<[EduHelper.CourseGrade]>?
    }

    enum CourseSchedule {
        @MMKVOptionalStorage(key: "Cached.courseScheduleCache")
        static var cache: Cached<CourseScheduleData>?
    }

    enum PhysicsExperiment {
        @MMKVOptionalStorage(key: "Cached.physicsExperimentScheduleCache")
        static var scheduleCache: Cached<[PhysicsExperimentHelper.Course]>?
    }
}
