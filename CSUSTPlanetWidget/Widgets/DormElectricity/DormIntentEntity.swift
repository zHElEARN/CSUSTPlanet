//
//  DormIntentEntity.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation

struct DormIntentEntity: AppEntity {
    var id: UUID

    var room: String

    var buildingName: String
    var campusName: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "宿舍")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(buildingName) \(room)")
    }

    static var defaultQuery = DormIntentQuery()

    init(id: UUID, room: String, buildingName: String, campusName: String) {
        self.id = id
        self.room = room
        self.buildingName = buildingName
        self.campusName = campusName
    }
}
