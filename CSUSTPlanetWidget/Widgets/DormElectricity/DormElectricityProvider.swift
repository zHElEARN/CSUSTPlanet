//
//  DormElectricityProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/20.
//

import AppIntents
import CSUSTKit
import Foundation
import GRDB
import OSLog
import WidgetKit

struct DormElectricityProvider: AppIntentTimelineProvider {

    #if DEBUG
    // 当学校电量不更新的时候，需要手动触发更新，打断电并修改shouldMock和mockElectricity可以配置新的电量值
    static var shouldMock: Bool = false
    static var mockElectricity: Double = 10
    #endif

    // MARK: - AppIntentTimelineProvider

    func placeholder(in context: Context) -> DormElectricityEntry {
        return .mockEntry
    }

    func snapshot(for configuration: DormElectricityAppIntent, in context: Context) async -> DormElectricityEntry {
        if context.isPreview {
            return .mockEntry
        }

        // Snapshot 应该尽量快，不进行网络请求，直接读取本地最新的缓存数据
        guard let dormID = configuration.dorm?.dormID else {
            return emptyEntry(for: configuration)
        }

        guard let pool = DatabaseManager.shared.pool else {
            return emptyEntry(for: configuration)
        }

        guard let dorm = try? await fetchLocalDorm(dormID: dormID, pool: pool) else {
            return emptyEntry(for: configuration)
        }

        let records = (try? await fetchChartRecords(dormID: dormID, limit: 50, pool: pool)) ?? []
        return DormElectricityEntry(
            date: .now,
            configuration: configuration,
            records: records,
            lastFetchDate: dorm.lastFetchDate,
            lastFetchElectricity: dorm.lastFetchElectricity
        )
    }

    func timeline(for configuration: DormElectricityAppIntent, in context: Context) async -> Timeline<DormElectricityEntry> {
        Logger.dormElectricityWidget.info("开始生成 timeline")

        // 设置下次刷新策略
        let nextUpdateDate = Date().addingTimeInterval(2 * 3600)
        let policy: TimelineReloadPolicy = .after(nextUpdateDate)

        // 校验配置
        guard let selectedDormEntity = configuration.dorm else {
            Logger.dormElectricityWidget.warning("配置中未选择宿舍")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: .never)
        }

        guard let dormID = selectedDormEntity.dormID else {
            Logger.dormElectricityWidget.warning("无法解析宿舍ID")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: policy)
        }

        guard let pool = DatabaseManager.shared.pool else {
            Logger.dormElectricityWidget.error("打开数据库失败")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: policy)
        }

        // 获取本地宿舍对象
        guard var dorm = try? await fetchLocalDorm(dormID: dormID, pool: pool) else {
            Logger.dormElectricityWidget.warning("未在数据库中找到对应的宿舍记录")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: policy)
        }

        // 解析校区与楼栋信息
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
            Logger.dormElectricityWidget.warning("无法解析校区枚举")
            let fallbackEntry = (try? await buildEntry(dorm: dorm, configuration: configuration, pool: pool)) ?? emptyEntry(for: configuration)
            return Timeline(entries: [fallbackEntry], policy: policy)
        }
        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

        // 拉取网络数据并执行更新逻辑
        do {
            #if DEBUG
            if Self.shouldMock {
                try await updateDatabaseIfNeeded(dormID: dormID, newElectricity: Self.mockElectricity, pool: pool)
            } else {
                let networkElectricity = try await CampusCardHelper().getElectricity(building: building, room: dorm.room)
                try await updateDatabaseIfNeeded(dormID: dormID, newElectricity: networkElectricity, pool: pool)
            }
            #else
            let networkElectricity = try await CampusCardHelper().getElectricity(building: building, room: dorm.room)
            try await updateDatabaseIfNeeded(dormID: dormID, newElectricity: networkElectricity, pool: pool)
            #endif

            if let refreshedDorm = try? await fetchLocalDorm(dormID: dormID, pool: pool) {
                dorm = refreshedDorm
            }
        } catch {
            Logger.dormElectricityWidget.error("网络请求电量失败: \(error.localizedDescription)")
            // 请求失败时，继续使用本地旧数据渲染
        }

        // 构建并返回最终的 Entry
        let entry = (try? await buildEntry(dorm: dorm, configuration: configuration, pool: pool)) ?? emptyEntry(for: configuration)
        Logger.dormElectricityWidget.info("timeline 生成完成")
        return Timeline(entries: [entry], policy: policy)
    }

    // MARK: - Helper Methods

    /// 构建空状态 Entry
    private func emptyEntry(for configuration: DormElectricityAppIntent) -> DormElectricityEntry {
        return DormElectricityEntry(date: .now, configuration: configuration, records: [], lastFetchDate: nil, lastFetchElectricity: nil)
    }

    /// 从本地数据库获取 Dorm 对象
    private func fetchLocalDorm(dormID: Int64, pool: DatabasePool) async throws -> DormGRDB? {
        try await pool.read { db in
            try DormGRDB.filter(key: dormID).fetchOne(db)
        }
    }

    /// 获取图表所需的最轻量级记录数据
    private func fetchChartRecords(dormID: Int64, limit: Int = 50, pool: DatabasePool) async throws -> [DormElectricityEntry.Record] {
        let records = try await pool.read { db in
            try ElectricityRecordGRDB
                .filter(ElectricityRecordGRDB.Columns.dormID == dormID)
                .order(ElectricityRecordGRDB.Columns.date.desc)
                .limit(limit)
                .fetchAll(db)
        }

        let entryRecords = records.map { DormElectricityEntry.Record(electricity: $0.electricity, date: $0.date) }
        return Array(entryRecords.reversed())
    }

    /// 执行核心的缓存比较与数据库更新逻辑
    private func updateDatabaseIfNeeded(dormID: Int64, newElectricity: Double, pool: DatabasePool) async throws {
        try await pool.write { db in
            try DormGRDB.updateElectricity(dormID: dormID, electricity: newElectricity, in: db)
        }
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), Constants.dbChangedCFNotificationName, nil, nil, true)
    }

    /// 统一构建最终的 Entry
    private func buildEntry(dorm: DormGRDB, configuration: DormElectricityAppIntent, pool: DatabasePool) async throws -> DormElectricityEntry {
        guard let dormID = dorm.id else {
            return emptyEntry(for: configuration)
        }

        let records = try await fetchChartRecords(dormID: dormID, limit: 50, pool: pool)
        return DormElectricityEntry(
            date: .now,
            configuration: configuration,
            records: records,
            lastFetchDate: dorm.lastFetchDate,
            lastFetchElectricity: dorm.lastFetchElectricity
        )
    }
}
