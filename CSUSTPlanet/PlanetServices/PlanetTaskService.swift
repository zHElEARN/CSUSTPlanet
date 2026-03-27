//
//  PlanetTaskService.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import Alamofire
import Combine
import Foundation
import GRDB
import OSLog

@MainActor
final class PlanetTaskService {
    enum PlanetTaskError: Error, LocalizedError {
        case databaseNotAvailable

        var errorDescription: String? {
            switch self {
            case .databaseNotAvailable:
                return "数据库不可用"
            }
        }
    }

    struct ElectricitySyncRequest: Encodable {
        let deviceToken: String
        let tasks: [ElectricityTask]
    }

    struct ElectricityTask: Encodable {
        let building: String
        let campus: String
        let notifyTime: String
        let room: String
    }

    static let shared = PlanetTaskService()

    private var cancellables = Set<AnyCancellable>()
    private var currentSyncTask: Task<Void, any Error>?

    private init() {
        startObservingNotifications()
    }

    private func startObservingNotifications() {
        Publishers.CombineLatest3(NotificationManager.shared.permissionStatusPublisher, NotificationManager.shared.tokenPublisher, PlanetAuthService.shared.authTokenPublisher)
            .compactMap { (permissionStatus, deviceToken, authToken) -> (NotificationPermissionStatus, String, String?)? in
                guard let permissionStatus = permissionStatus, let deviceToken = deviceToken else {
                    return nil
                }
                return (permissionStatus, deviceToken, authToken)
            }
            .removeDuplicates { prev, current in
                return prev == current
            }
            .sink { [weak self] permissionStatus, deviceToken, authToken in
                guard let self = self else { return }
                guard let authToken = authToken else {
                    self.currentSyncTask?.cancel()
                    return
                }
                Task {
                    do {
                        try await self.sync(permissionStatus: permissionStatus, deviceToken: deviceToken, authToken: authToken)
                    } catch {
                        Logger.planetTaskService.error("同步任务失败: \(error.localizedDescription)")
                    }
                }
            }
            .store(in: &cancellables)
    }

    func sync(permissionStatus: NotificationPermissionStatus, deviceToken: String, authToken: String, tasks: [ElectricityTask]? = nil) async throws {
        currentSyncTask?.cancel()

        let syncTask = Task {
            try Task.checkCancellation()

            if permissionStatus == .authorized {
                let tasksToSync: [ElectricityTask]
                if let providedTasks = tasks {
                    tasksToSync = providedTasks
                } else {
                    tasksToSync = try await getScheduledTasks()
                }

                try Task.checkCancellation()
                try await syncElectricity(authToken: authToken, deviceToken: deviceToken, tasks: tasksToSync)

            } else {
                try Task.checkCancellation()
                try await syncElectricity(authToken: authToken, deviceToken: deviceToken, tasks: [])
            }
        }

        currentSyncTask = syncTask
        try await syncTask.value
    }

    private func getScheduledTasks() async throws -> [ElectricityTask] {
        guard let pool = DatabaseManager.shared.pool else { throw PlanetTaskError.databaseNotAvailable }

        return try await pool.read { (db: Database) -> [ElectricityTask] in
            let dorms =
                try DormGRDB
                .filter(DormGRDB.Columns.scheduleHour != nil && DormGRDB.Columns.scheduleMinute != nil)
                .fetchAll(db)

            return dorms.map { dorm in
                ElectricityTask(
                    building: dorm.buildingName,
                    campus: dorm.campusName,
                    notifyTime: String(format: "%02d:%02d", dorm.scheduleHour ?? 0, dorm.scheduleMinute ?? 0),
                    room: dorm.room
                )
            }
        }
    }

    private func syncElectricity(authToken: String, deviceToken: String, tasks: [ElectricityTask]) async throws {
        let headers: HTTPHeaders = [.authorization(bearerToken: authToken)]

        _ = try await AF.request(
            "\(Constants.backendHost)/task/electricity",
            method: .post,
            parameters: ElectricitySyncRequest(deviceToken: deviceToken, tasks: tasks),
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate(statusCode: [204])
        .serializingData()
        .value
    }
}
