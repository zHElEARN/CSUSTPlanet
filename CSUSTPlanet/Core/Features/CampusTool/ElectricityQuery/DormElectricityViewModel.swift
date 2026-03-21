//
//  DormRowViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/10.
//

import Alamofire
import CSUSTKit
import Foundation
import SwiftData
import SwiftUI
import WidgetKit

@MainActor
@Observable
class DormElectricityViewModel {
    private let campusCardHelper = CampusCardHelper()
    private let modelContext = SharedModelUtil.mainContext

    var errorToast = ToastState.errorTitle

    var isQueryingElectricity: Bool = false

    var isConfirmationDialogPresented: Bool = false
    var isCancelScheduleAlertPresented: Bool = false
    var isTermsPresented: Bool = false
    var isShowNotificationSettings: Bool = false

    var isScheduleLoading: Bool = false

    var sortedRecords: [ElectricityRecord] = []

    private let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return dateFormatter
    }()

    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }

    func removeSchedule(_ dorm: Dorm) {
        guard dorm.scheduleEnabled else { return }
        isScheduleLoading = true
        Task {
            defer {
                isScheduleLoading = false
            }
            do {
                dorm.scheduleHour = nil
                dorm.scheduleMinute = nil
                try await ElectricityBindingUtil.syncThrows()
                try modelContext.save()
            } catch {
                modelContext.rollback()
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    func handleQueryElectricity(_ dorm: Dorm) {
        isQueryingElectricity = true
        guard let campus = CampusCardHelper.Campus(rawValue: dorm.campusName) else {
            errorToast.show(message: "无效的校区ID")
            return
        }
        let building = CampusCardHelper.Building(name: dorm.buildingName, id: dorm.buildingID, campus: campus)
        Task {
            do {
                defer {
                    isQueryingElectricity = false
                }
                let electricity = try await campusCardHelper.getElectricity(building: building, room: dorm.room)

                let now = Date()
                if let lastFetchElectricity = dorm.lastFetchElectricity, abs(lastFetchElectricity - electricity) < 0.001 {
                    // 电量未变化，仅更新查询时间
                    dorm.lastFetchDate = now
                } else {
                    // 电量变化，记录新数据
                    let record = ElectricityRecord(electricity: electricity, date: now, dorm: dorm)
                    modelContext.insert(record)
                    dorm.lastFetchDate = now
                    dorm.lastFetchElectricity = electricity
                }

                try modelContext.save()
            } catch {
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    func deleteDorm(_ dorm: Dorm) {
        Task {
            do {
                let scheduleEnabled = dorm.scheduleEnabled
                modelContext.delete(dorm)
                if scheduleEnabled {
                    await ElectricityBindingUtil.sync()
                }
                try modelContext.save()
            } catch {
                modelContext.rollback()
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    func deleteAllRecords(_ dorm: Dorm) {
        for record in dorm.records ?? [] {
            modelContext.delete(record)
        }
        do {
            try modelContext.save()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func updateSortedRecords(for dorm: Dorm) {
        self.sortedRecords = dorm.records?.sorted(by: { $0.date > $1.date }) ?? []
    }

    func deleteRecord(record: ElectricityRecord) {
        if let index = sortedRecords.firstIndex(of: record) {
            sortedRecords.remove(at: index)
        }
        modelContext.delete(record)
        do {
            try modelContext.save()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }

    func handleNotificationSettings(_ dorm: Dorm, scheduleHour: Int, scheduleMinute: Int) {
        Task {
            do {
                dorm.scheduleHour = scheduleHour
                dorm.scheduleMinute = scheduleMinute
                try await ElectricityBindingUtil.syncThrows()
                try modelContext.save()
            } catch {
                modelContext.rollback()
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    func toggleFavorite(_ dorm: Dorm) {
        do {
            if dorm.isFavorite {
                dorm.isFavorite = false
            } else {
                let descriptor = FetchDescriptor<Dorm>(predicate: #Predicate { $0.isFavorite == true })
                let favorites = try modelContext.fetch(descriptor)
                for favorite in favorites {
                    favorite.isFavorite = false
                }
                dorm.isFavorite = true
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorToast.show(message: error.localizedDescription)
        }
    }
}
