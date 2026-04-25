//
//  CourseETAManager.swift
//  CSUSTPlanet
//
//  Created by 韦亦航 on 2026/4/25.
//

import CoreLocation
import OSLog
import SwiftUI
import Observation
import CSUSTKit

@MainActor
@Observable
final class CourseETAManager: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    static let shared = CourseETAManager()
    
    private let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D? = nil
    var allBuildings: [PlanetConfigService.Feature] = []
    
    #if DEBUG
    private let etaLogger = Logger(subsystem: "com.csustplanet.CourseSchedule", category: "CourseETA")
    #endif
    
    private var coordinateCache: [String: CLLocationCoordinate2D] = [:]
    
    private var isFetchingMapData = false
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        Task {
            await loadMapData()
        }
    }
    
    private var cacheURL: URL? {
        let fileManager = FileManager.default
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        return cacheDir.appendingPathComponent("map.json")
    }

    func loadMapData() async {
        guard allBuildings.isEmpty, !isFetchingMapData else { return }
        
        if let url = cacheURL,
           let data = try? Data(contentsOf: url),
           let geoJSON = try? JSONDecoder().decode(PlanetConfigService.GeoJSON.self, from: data) {
            self.allBuildings = geoJSON.features
        }
        
        isFetchingMapData = true
        defer { isFetchingMapData = false }
        
        do {
            let geoJSON = try await PlanetConfigService.campusMap()
            self.allBuildings = geoJSON.features
            
            if let url = cacheURL, let data = try? JSONEncoder().encode(geoJSON) {
                try? data.write(to: url)
            }
        } catch {
            print("CourseETAManager Failed to load map data from network: \(error)")
        }
    }
    
    nonisolated private func isAuthorized(status: CLAuthorizationStatus) -> Bool {
        #if os(macOS)
        return status == .authorizedAlways || status == .authorized
        #else
        return status == .authorizedWhenInUse || status == .authorizedAlways
        #endif
    }

    func requestLocationIfAuthorized() {
        let status = locationManager.authorizationStatus
        if isAuthorized(status: status) {
            locationManager.requestLocation()
        } else if status == .notDetermined {
            #if os(macOS)
            locationManager.requestAlwaysAuthorization()
            #else
            locationManager.requestWhenInUseAuthorization()
            #endif
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if self.isAuthorized(status: status) {
                self.locationManager.requestLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.userLocation = location.coordinate
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("CourseETAManager Location Error: \(error.localizedDescription)")
    }
    
    func calculateETA(to session: EduHelper.ScheduleSession) -> String? {
        guard session.hasValidClassroom else {
            return "未分配教室"
        }
        
        let classroomName = session.classroom!
        
        guard let userLoc = userLocation else {
            #if DEBUG
            etaLogger.debug("无法计算到达时间: 尚未获取到用户定位 (未授权或正在获取中)")
            #endif
            return nil
        }
        let targetCoordinate: CLLocationCoordinate2D
        let featureName: String
        
        if let cached = coordinateCache[classroomName] {
            targetCoordinate = cached
            featureName = classroomName
        } else {
            guard let feature = session.matchedFeature(in: allBuildings) else {
                #if DEBUG
                etaLogger.debug("无法计算到达时间: 地图中未匹配到该教室建筑 (\(classroomName, privacy: .public))")
                #endif
                return nil
            }
            guard let center = feature.centerCoordinateWGS84() else {
                #if DEBUG
                etaLogger.debug("无法计算到达时间: 建筑坐标数据无效 (\(feature.properties.name, privacy: .public))")
                #endif
                return nil
            }
            coordinateCache[classroomName] = center
            targetCoordinate = center
            featureName = feature.properties.name
        }
        
        let start = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        let end = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
        
        let straightDistance = start.distance(from: end)
        
        // 假设曲折系数为 1.3，正常步行速度为 1.2 m/s
        let estimatedTimeInSeconds = (straightDistance * 1.3) / 1.2
        
        let result: String
        let totalMinutes = Int(ceil(estimatedTimeInSeconds / 60.0))
        
        if totalMinutes < 1 {
            result = "小于1分钟"
        } else if totalMinutes < 60 {
            result = "约 \(totalMinutes) 分钟"
        } else {
            let hours = totalMinutes / 60
            let remainingMinutes = totalMinutes % 60
            if remainingMinutes == 0 {
                result = "约 \(hours) 小时"
            } else {
                result = "约 \(hours) 小时 \(remainingMinutes) 分钟"
            }
        }
        
        #if DEBUG
        // 使用 OSLog，利用内置插值避免手动 String(format:) 内存分配，且系统自动带精确时间戳
        etaLogger.debug("✅ 计算到达时间: 从用户当前位置到 \(featureName, privacy: .public) - 直线距离: \(straightDistance, format: .fixed(precision: 1))m, 估算步行耗时: \(estimatedTimeInSeconds, format: .fixed(precision: 1))s, UI显示: \(result, privacy: .public)")
        #endif
        
        return result
    }
}

extension PlanetConfigService.Feature {
    func centerCoordinateWGS84() -> CLLocationCoordinate2D? {
        guard let firstRing = geometry.coordinates.first, !firstRing.isEmpty else { return nil }
        let totalLat = firstRing.reduce(0.0) { $0 + $1[1] }
        let totalLon = firstRing.reduce(0.0) { $0 + $1[0] }
        let count = Double(firstRing.count)
        return CLLocationCoordinate2D(latitude: totalLat / count, longitude: totalLon / count)
    }
}

extension EduHelper.ScheduleSession {
    var hasValidClassroom: Bool {
        guard let name = classroom, !name.isEmpty, name != "未知", !name.contains("未分配") else {
            return false
        }
        return true
    }
    
    var displayClassroom: String {
        hasValidClassroom ? classroom! : "未安排教室"
    }
}
