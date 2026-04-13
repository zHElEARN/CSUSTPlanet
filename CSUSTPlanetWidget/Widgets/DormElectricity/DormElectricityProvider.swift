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

// MARK: - AppIntentTimelineProvider

struct DormElectricityProvider: AppIntentTimelineProvider {
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
        Logger.dormElectricityWidget.info("开始生成 timeline (仅读取本地缓存)")

        guard let selectedDormEntity = configuration.dorm,
            let dormID = selectedDormEntity.dormID,
            let pool = DatabaseManager.shared.pool
        else {
            Logger.dormElectricityWidget.warning("配置不完整或数据库连接失败")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: .never)
        }

        guard let dorm = try? await fetchLocalDorm(dormID: dormID, pool: pool) else {
            Logger.dormElectricityWidget.warning("未在数据库中找到对应的宿舍记录")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: .never)
        }

        let entry = (try? await buildEntry(dorm: dorm, configuration: configuration, pool: pool)) ?? emptyEntry(for: configuration)
        Logger.dormElectricityWidget.info("timeline 生成完成")

        return Timeline(entries: [entry], policy: .never)
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
