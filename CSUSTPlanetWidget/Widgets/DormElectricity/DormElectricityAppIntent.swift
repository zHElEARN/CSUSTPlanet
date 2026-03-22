//
//  DormElectricityAppIntent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/20.
//

import AppIntents
import CSUSTKit
import WidgetKit

struct DormElectricityAppIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "宿舍电量"
    static var description = IntentDescription("选择一个宿舍查看其用电情况")

    @Parameter(title: "宿舍")
    var dorm: DormIntentEntity?

    static let mockIntent = {
        let intent = DormElectricityAppIntent()
        intent.dorm = DormIntentEntity(id: 1, room: "A233", buildingName: "至诚轩5栋A区", campusName: "云塘校区")
        return intent
    }()
}
