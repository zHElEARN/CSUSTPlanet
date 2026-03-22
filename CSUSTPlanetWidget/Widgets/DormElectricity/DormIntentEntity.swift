//
//  DormIntentEntity.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/21.
//

import AppIntents
import Foundation

struct DormIntentEntity: AppEntity {
    var id: String

    var room: String

    var buildingName: String
    var campusName: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "宿舍")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(buildingName) \(room)")
    }

    static var defaultQuery = DormIntentQuery()

    var dormID: Int64? { Int64(id) }

    init(id: String, room: String, buildingName: String, campusName: String) {
        self.id = id
        self.room = room
        self.buildingName = buildingName
        self.campusName = campusName
    }

    init(id: Int64, room: String, buildingName: String, campusName: String) {
        self.init(id: String(id), room: room, buildingName: buildingName, campusName: campusName)
    }
}
