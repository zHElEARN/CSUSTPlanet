//
//  FeatureTabID.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/4/12.
//

import Foundation
import SwiftUI

// MARK: - FeatureTabID

enum FeatureTabID: Hashable, CaseIterable {
    case courseSchedule
    case gradeQuery
    case examSchedule
    case gradeAnalysis

    case courses
    case assignments
    case chaoxingAssignments

    case electricityQuery
    case availableClassroom
    case campusMap
    case schoolCalendar
    case electricityRecharge
    case webVPNConverter
    case eval

    case physicsExperimentSchedule
    case physicsExperimentGrade

    case cet
    case mandarin
    case ncre

    var name: String {
        switch self {
        case .courseSchedule: return "我的课表"
        case .gradeQuery: return "成绩查询"
        case .examSchedule: return "考试安排"
        case .gradeAnalysis: return "成绩分析"
        case .courses: return "课程"
        case .assignments: return "作业"
        case .chaoxingAssignments: return "学习通作业"
        case .electricityQuery: return "电量查询"
        case .availableClassroom: return "空教室查询"
        case .campusMap: return "校园地图"
        case .schoolCalendar: return "校历"
        case .electricityRecharge: return "电费充值"
        case .webVPNConverter: return "WebVPN"
        case .eval: return "评教系统"
        case .physicsExperimentSchedule: return "实验安排"
        case .physicsExperimentGrade: return "实验成绩"
        case .cet: return "四六级查询"
        case .mandarin: return "普通话查询"
        case .ncre: return "计算机等级查询"
        }
    }

    var trackSegment: String {
        switch self {
        case .courseSchedule: return "CourseSchedule"
        case .gradeQuery: return "GradeQuery"
        case .examSchedule: return "ExamSchedule"
        case .gradeAnalysis: return "GradeAnalysis"
        case .courses: return "Courses"
        case .assignments: return "Assignments"
        case .chaoxingAssignments: return "ChaoxingAssignments"
        case .electricityQuery: return "DormList"
        case .availableClassroom: return "AvailableClassroom"
        case .campusMap: return "CampusMap"
        case .schoolCalendar: return "SchoolCalendarList"
        case .electricityRecharge: return "ElectricityRecharge"
        case .webVPNConverter: return "WebVPNConverter"
        case .eval: return "Eval"
        case .physicsExperimentSchedule: return "PhysicsExperimentSchedule"
        case .physicsExperimentGrade: return "PhysicsExperimentGrade"
        case .cet: return "CET"
        case .mandarin: return "Mandarin"
        case .ncre: return "NCRE"
        }
    }

    var systemImage: String {
        switch self {
        case .courseSchedule: return "calendar"
        case .gradeQuery: return "doc.text.magnifyingglass"
        case .examSchedule: return "pencil.and.outline"
        case .gradeAnalysis: return "chart.bar.xaxis"
        case .courses: return "books.vertical.fill"
        case .assignments: return "list.bullet.clipboard"
        case .chaoxingAssignments: return "list.bullet.clipboard"
        case .electricityQuery: return "bolt.fill"
        case .availableClassroom: return "building.2.fill"
        case .campusMap: return "map.fill"
        case .eval: return "pencil.and.list.clipboard"
        case .schoolCalendar: return "calendar.badge.clock"
        case .electricityRecharge: return "creditcard.fill"
        case .webVPNConverter: return "lock.shield"
        case .physicsExperimentSchedule: return "calendar"
        case .physicsExperimentGrade: return "doc.text"
        case .cet: return "character.book.closed"
        case .mandarin: return "mic.circle.fill"
        case .ncre: return "desktopcomputer"
        }
    }

    var rootRoute: AppRoute {
        switch self {
        case .courseSchedule:
            return .features(.education(.courseSchedule(.main)))
        case .gradeQuery:
            return .features(.education(.gradeQuery(.main)))
        case .examSchedule:
            return .features(.education(.examSchedule))
        case .gradeAnalysis:
            return .features(.education(.gradeAnalysis))
        case .courses:
            return .features(.mooc(.courses(.main)))
        case .assignments:
            return .features(.mooc(.assignments))
        case .chaoxingAssignments:
            return .features(.chaoxingAssignments)
        case .electricityQuery:
            return .features(.campusTool(.dormList(.main)))
        case .availableClassroom:
            return .features(.campusTool(.availableClassroom))
        case .campusMap:
            return .features(.campusTool(.campusMap))
        case .schoolCalendar:
            return .features(.campusTool(.schoolCalendarList(.main)))
        case .electricityRecharge:
            return .features(.campusTool(.electricityRecharge))
        case .webVPNConverter:
            return .features(.campusTool(.webVPNConverter))
        case .eval:
            return .features(.campusTool(.eval))
        case .physicsExperimentSchedule:
            return .features(.physicsExperiment(.schedule))
        case .physicsExperimentGrade:
            return .features(.physicsExperiment(.grade))
        case .cet:
            return .features(.examQuery(.cet))
        case .mandarin:
            return .features(.examQuery(.mandarin))
        case .ncre:
            return .features(.examQuery(.ncre))
        }
    }
}
