//
//  RefreshElectricityIntent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import CSUSTKit
import OSLog
import WidgetKit

struct RefreshElectricityTimelineIntent: AppIntent {
    static var title: LocalizedStringResource = "刷新宿舍电量"
    static var isDiscoverable: Bool = false

    @Parameter(title: "宿舍")
    var dorm: DormIntentEntity?

    init() {}

    init(dorm: DormIntentEntity) {
        self.dorm = dorm
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let selectedDormEntity = dorm,
            let dormID = selectedDormEntity.dormID
        else {
            Logger.dormElectricityWidget.warning("Intent未获取到宿舍ID")
            return .result()
        }

        guard let pool = DatabaseManager.shared.pool else {
            Logger.dormElectricityWidget.error("Intent打开数据库失败")
            return .result()
        }

        // 获取本地宿舍对象
        guard
            let localDorm = try? await pool.read({ db in
                try DormGRDB.filter(key: dormID).fetchOne(db)
            })
        else {
            Logger.dormElectricityWidget.warning("未在数据库中找到对应的宿舍记录")
            return .result()
        }

        // 解析校区与楼栋信息
        guard let campus = CampusCardHelper.Campus(rawValue: localDorm.campusName) else {
            Logger.dormElectricityWidget.warning("无法解析校区枚举")
            return .result()
        }
        let building = CampusCardHelper.Building(name: localDorm.buildingName, id: localDorm.buildingID, campus: campus)

        // 拉取网络数据并更新数据库
        do {
            let networkElectricity = try await CampusCardHelper().getElectricity(building: building, room: localDorm.room)
            try await pool.write { db in
                try DormGRDB.updateElectricity(dormID: dormID, electricity: networkElectricity, in: db)
            }
            Logger.dormElectricityWidget.info("AppIntent 手动刷新电量成功")
        } catch {
            Logger.dormElectricityWidget.error("网络请求电量失败: \(error.localizedDescription)")
        }

        return .result()
    }
}
