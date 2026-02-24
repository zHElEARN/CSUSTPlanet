//
//  DayOfWeek+Formatter.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/25.
//

import CSUSTKit
import Foundation

extension EduHelper.DayOfWeek {
    var chineseShortString: String {
        switch self {
        case .monday: return "一"
        case .tuesday: return "二"
        case .wednesday: return "三"
        case .thursday: return "四"
        case .friday: return "五"
        case .saturday: return "六"
        case .sunday: return "日"
        }
    }

    var chineseLongString: String {
        "星期" + chineseShortString
    }
}
