//
//  CourseSchedule.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/23.
//

import CSUSTKit
import Foundation
import SwiftUI

struct CourseDisplayInfo: Identifiable, Codable {
    var id = UUID()
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
}

struct CourseScheduleData: Codable {
    var semester: String?
    var semesterStartDate: Date
    var courses: [EduHelper.Course]
}

extension EduHelper.ScheduleSession {
    /// 从上课地点字符串中提取建筑简称
    public var buildingAbbreviation: String? {
        guard let classroom = classroom else { return nil }
        
        // 使用正则表达式精确匹配已知的建筑简称模式
        let pattern = /^(金\d+[A-Z]?|云(?:工[一二三][AB]|理[12]|文科[DE]|综教[A-C]|体育馆|西田径场)|金(?:体育馆|东田径场|西田径场))/
        if let match = classroom.firstMatch(of: pattern) {
            return String(match.0)
        }
        
        // 兜底逻辑：如果正则没有命中，尝试按照 '-' 分割
        if let dashIndex = classroom.firstIndex(of: "-") {
            return String(classroom[..<dashIndex])
        }
        return classroom
    }
    
    /// 根据映射关系获取建筑全称
    public var buildingFullName: String? {
        guard let abbr = buildingAbbreviation else { return nil }
        
        let buildingMap: [String: String] = [
            // 云塘校区
            "云工一A": "工科1号楼",
            "云工一B": "工科1号楼",
            "云工二A": "工科2号楼",
            "云工二B": "工科2号楼",
            "云工三A": "工科3号楼",
            "云工三B": "工科3号楼",
            "云理1": "理科楼",
            "云理2": "理科楼",
            "云文科D": "文科楼",
            "云文科E": "文科楼",
            "云综教A": "综合教学楼",
            "云综教B": "综合教学楼",
            "云综教C": "综合教学楼",
            "云体育馆": "体育馆",
            "云西田径场": "田径场",
            
            // 金盆岭校区
            "金1A": "1号教学楼（电苑楼）",
            "金1B": "1号教学楼（电苑楼）",
            "金3": "3号教学楼",
            "金4": "4号教学楼",
            "金5": "5号教学楼",
            "金6": "6号教学楼",
            "金7": "7号教学楼",
            "金8": "8号教学楼（经管大楼）",
            "金9": "9号教学楼",
            "金10": "10号教学楼",
            "金11": "11号教学楼",
            "金12": "12号教学楼",
            "金13": "13号教学楼",
            "金14": "14号教学楼",
            "金15": "15号教学楼",
            "金16": "16号教学楼",
            "金体育馆": "体育馆",
            "金东田径场": "田径运动场",
            "金西田径场": "田径运动场"
        ]
        
        return buildingMap[abbr] ?? abbr
    }
    
    /// 所属校区
    public var campusName: String? {
        guard let abbr = buildingAbbreviation else { return nil }
        if abbr.hasPrefix("云") {
            return "云塘"
        } else if abbr.hasPrefix("金") {
            return "金盆岭"
        }
        return nil
    }

}
