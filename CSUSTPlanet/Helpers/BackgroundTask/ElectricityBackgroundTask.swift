//
//  ElectricityBackgroundTask.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

#if os(iOS)

import BackgroundTasks
import CSUSTKit
import Foundation
import OSLog
import SwiftData
import UserNotifications

struct ElectricityBackgroundTask: BackgroundTaskProvider {
    let identifier: String = "electricity"

    let title: String = "查询宿舍电量"
    let description: String = "在后台查询当前收藏宿舍电量，并在电量有更新时发送通知"

    func perform() async -> Bool {
        Logger.electricityBackgroundTask.debug("开始后台获取电量任务: \(self.identifier)")

        do {
            let modelContext = SharedModelUtil.context

            var targetDorm: Dorm? = nil

            let favoritePredicate = #Predicate<Dorm> { $0.isFavorite == true }
            var favoriteDescriptor = FetchDescriptor<Dorm>(predicate: favoritePredicate)
            favoriteDescriptor.fetchLimit = 1
            targetDorm = try modelContext.fetch(favoriteDescriptor).first

            if targetDorm == nil {
                Logger.electricityBackgroundTask.debug("未找到 Favorite 宿舍，尝试获取列表中的第一个宿舍")
                var anyDormDescriptor = FetchDescriptor<Dorm>()
                anyDormDescriptor.fetchLimit = 1
                targetDorm = try modelContext.fetch(anyDormDescriptor).first
            }

            guard let dorm = targetDorm else {
                Logger.electricityBackgroundTask.debug("数据库中没有任何宿舍，跳过电量查询")
                return true
            }

            guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
                Logger.electricityBackgroundTask.error("宿舍 \(dorm.room) 无法解析校区枚举: \(dorm.campusName)")
                return false
            }
            let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

            let helper = CampusCardHelper()
            var fetchedElectricity: Double? = nil

            for i in 1...3 {
                try Task.checkCancellation()
                do {
                    fetchedElectricity = try await helper.getElectricity(building: building, room: dorm.room)
                    Logger.electricityBackgroundTask.debug("第 \(i) 次尝试获取宿舍 \(dorm.buildingName)-\(dorm.room) 电量成功: \(fetchedElectricity!)")
                    break
                } catch {
                    Logger.electricityBackgroundTask.warning("第 \(i) 次获取电量失败: \(error.localizedDescription)")
                    if i < 3 { try await Task.sleep(for: .seconds(2)) }
                }
            }

            guard let newElectricity = fetchedElectricity else {
                Logger.electricityBackgroundTask.error("获取电量彻底失败: 多次尝试均未成功")
                return false
            }

            let dormID = dorm.id
            let recordPredicate = #Predicate<ElectricityRecord> { $0.dorm?.id == dormID }
            var recordDescriptor = FetchDescriptor<ElectricityRecord>(predicate: recordPredicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
            recordDescriptor.fetchLimit = 1
            let lastElectricity = try modelContext.fetch(recordDescriptor).first?.electricity

            let now = Date()

            if let lastElectricity = lastElectricity, abs(lastElectricity - newElectricity) < 0.001 {
                Logger.electricityBackgroundTask.debug("\(dorm.buildingName)-\(dorm.room) 电量未变化，仅更新 lastFetchDate")
                dorm.lastFetchDate = now
            } else {
                Logger.electricityBackgroundTask.debug("\(dorm.buildingName)-\(dorm.room) 电量发生变化，更新数据并发送通知")

                let record = ElectricityRecord(electricity: newElectricity, date: now, dorm: dorm)
                modelContext.insert(record)
                dorm.lastFetchDate = now
                dorm.lastFetchElectricity = newElectricity

                let content = UNMutableNotificationContent()
                content.title = "宿舍电量更新"
                content.body = "\(dorm.buildingName) \(dorm.room) 当前电量: \(String(format: "%.2f", newElectricity)) 度"
                content.sound = .default
                content.badge = 0

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
                do {
                    try await UNUserNotificationCenter.current().add(request)
                    Logger.electricityBackgroundTask.debug("电量更新推送调度成功")
                } catch {
                    Logger.electricityBackgroundTask.error("推送调度失败: \(error.localizedDescription)")
                }
            }

            if modelContext.hasChanges {
                try modelContext.save()
                Logger.electricityBackgroundTask.debug("电量数据库保存成功")
            }

            return true

        } catch {
            if error is CancellationError {
                Logger.electricityBackgroundTask.debug("后台任务因超时被取消")
                return false
            }
            Logger.electricityBackgroundTask.error("后台任务执行发生意外错误: \(error.localizedDescription)")
            return false
        }

    }
}
#endif
