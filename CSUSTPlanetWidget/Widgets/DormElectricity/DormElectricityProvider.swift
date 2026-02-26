//
//  DormElectricityProvider.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/20.
//

import AppIntents
import CSUSTKit
import OSLog
import SwiftData
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

        let modelContext = SharedModelUtil.context

        // Snapshot 应该尽量快，不进行网络请求，直接读取本地最新的缓存数据
        guard let dormID = configuration.dorm?.id,
            let dorm = fetchLocalDorm(dormID: dormID, context: modelContext)
        else {
            return emptyEntry(for: configuration)
        }

        let records = fetchChartRecords(dormID: dormID, limit: 50, context: modelContext)
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

        let modelContext = SharedModelUtil.context

        // 获取本地宿舍对象
        guard let dorm = fetchLocalDorm(dormID: selectedDormEntity.id, context: modelContext) else {
            Logger.dormElectricityWidget.warning("未在数据库中找到对应的宿舍记录")
            return Timeline(entries: [emptyEntry(for: configuration)], policy: policy)
        }

        // 解析校区与楼栋信息
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
            Logger.dormElectricityWidget.warning("无法解析校区枚举")
            return Timeline(entries: [buildEntry(dorm: dorm, configuration: configuration, context: modelContext)], policy: policy)
        }
        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)

        // 拉取网络数据并执行更新逻辑
        do {
            #if DEBUG
                if Self.shouldMock {
                    updateDatabaseIfNeeded(dorm: dorm, newElectricity: Self.mockElectricity, context: modelContext)
                } else {
                    let networkElectricity = try await CampusCardHelper().getElectricity(building: building, room: dorm.room)
                    updateDatabaseIfNeeded(dorm: dorm, newElectricity: networkElectricity, context: modelContext)
                }
            #else
                let networkElectricity = try await CampusCardHelper().getElectricity(building: building, room: dorm.room)
                updateDatabaseIfNeeded(dorm: dorm, newElectricity: networkElectricity, context: modelContext)
            #endif
        } catch {
            Logger.dormElectricityWidget.error("网络请求电量失败: \(error.localizedDescription)")
            // 请求失败时，继续使用本地旧数据渲染
        }

        // 构建并返回最终的 Entry
        let entry = buildEntry(dorm: dorm, configuration: configuration, context: modelContext)
        Logger.dormElectricityWidget.info("timeline 生成完成")
        return Timeline(entries: [entry], policy: policy)
    }

    // MARK: - Helper Methods

    /// 构建空状态 Entry
    private func emptyEntry(for configuration: DormElectricityAppIntent) -> DormElectricityEntry {
        return DormElectricityEntry(date: .now, configuration: configuration, records: [], lastFetchDate: nil, lastFetchElectricity: nil)
    }

    /// 从本地数据库获取 Dorm 对象
    private func fetchLocalDorm(dormID: UUID, context: ModelContext) -> Dorm? {
        let predicate = #Predicate<Dorm> { $0.id == dormID }
        var descriptor = FetchDescriptor<Dorm>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }

    /// 获取图表所需的最轻量级记录数据
    private func fetchChartRecords(dormID: UUID, limit: Int = 50, context: ModelContext) -> [DormElectricityEntry.Record] {
        let predicate = #Predicate<ElectricityRecord> { $0.dorm?.id == dormID }
        var descriptor = FetchDescriptor<ElectricityRecord>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit

        guard let models = try? context.fetch(descriptor) else { return [] }

        return models.map { DormElectricityEntry.Record(electricity: $0.electricity, date: $0.date) }
            .sorted { $0.date < $1.date }
    }

    /// 获取该宿舍本地最新的一条电量数值
    private func fetchLastElectricityValue(dormID: UUID, context: ModelContext) -> Double? {
        let predicate = #Predicate<ElectricityRecord> { $0.dorm?.id == dormID }
        var descriptor = FetchDescriptor<ElectricityRecord>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first?.electricity
    }

    /// 执行核心的缓存比较与数据库更新逻辑
    private func updateDatabaseIfNeeded(dorm: Dorm, newElectricity: Double, context: ModelContext) {
        let lastElectricity = fetchLastElectricityValue(dormID: dorm.id, context: context)
        let now = Date()

        if let lastElectricity = lastElectricity, abs(lastElectricity - newElectricity) < 0.001 {
            Logger.dormElectricityWidget.info("电量未变化，仅更新 lastFetchDate")
            dorm.lastFetchDate = now
        } else {
            Logger.dormElectricityWidget.info("电量发生变化，插入新记录")
            let record = ElectricityRecord(electricity: newElectricity, date: now, dorm: dorm)
            context.insert(record)
            dorm.lastFetchDate = now
            dorm.lastFetchElectricity = newElectricity
        }

        do {
            try context.save()
        } catch {
            Logger.dormElectricityWidget.error("保存数据库失败: \(error.localizedDescription)")
        }
    }

    /// 统一构建最终的 Entry
    private func buildEntry(dorm: Dorm, configuration: DormElectricityAppIntent, context: ModelContext) -> DormElectricityEntry {
        let records = fetchChartRecords(dormID: dorm.id, limit: 50, context: context)
        return DormElectricityEntry(
            date: .now,
            configuration: configuration,
            records: records,
            lastFetchDate: dorm.lastFetchDate,
            lastFetchElectricity: dorm.lastFetchElectricity
        )
    }
}
