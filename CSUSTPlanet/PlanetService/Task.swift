//
//  Task.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/25.
//

import Alamofire
import Foundation

extension PlanetService {
    enum Task {
        enum TaskError: Error {
            case invalidBackendURL
            case missingBackendToken
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
    }
}

extension PlanetService.Task {
    static func syncElectricity(
        deviceToken: String,
        tasks: [ElectricityTask]
    ) async throws {
        let urlString = "\(Constants.backendHost)/task/electricity"
        guard let url = URL(string: urlString) else {
            throw TaskError.invalidBackendURL
        }

        guard let backendToken = PlanetService.authToken, !backendToken.isEmpty else {
            throw TaskError.missingBackendToken
        }

        let headers: HTTPHeaders = [
            .authorization(bearerToken: backendToken)
        ]

        _ = try await AF.request(
            url,
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
