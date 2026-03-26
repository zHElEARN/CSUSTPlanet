//
//  PlanetTaskService.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/25.
//

import Alamofire
import Foundation

enum PlanetTaskService {
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

    static func syncElectricity(
        authToken: String,
        deviceToken: String,
        tasks: [ElectricityTask]
    ) async throws {
        let headers: HTTPHeaders = [
            .authorization(bearerToken: authToken)
        ]

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
