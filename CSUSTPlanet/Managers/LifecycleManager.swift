//
//  LifecycleManager.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import Combine
import Foundation
import OSLog
import SwiftUI

@MainActor
final class LifecycleManager {
    enum Event: Equatable {
        case didBecomeActive(resumeAfter: TimeInterval?)
        case didBecomeInactive
        case didEnterBackground
    }

    static let shared = LifecycleManager()

    private let scenePhaseSubject = CurrentValueSubject<ScenePhase?, Never>(nil)
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var isFirstAppearance = true
    private var lastBackgroundDate: Date?

    private init() {}

    var currentScenePhase: ScenePhase? {
        scenePhaseSubject.value
    }

    var scenePhases: AnyPublisher<ScenePhase?, Never> {
        scenePhaseSubject.eraseToAnyPublisher()
    }

    var events: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    func publishScenePhaseChange(to newPhase: ScenePhase) {
        let now = Date()

        scenePhaseSubject.send(newPhase)

        switch newPhase {
        case .active:
            let resumeAfter: TimeInterval?
            if isFirstAppearance {
                resumeAfter = nil
                isFirstAppearance = false
                Logger.appLifecycleManager.debug("App首次进入.active状态，跳过didBecomeActive事件派发")
                return
            } else if let lastBackgroundDate {
                resumeAfter = now.timeIntervalSince(lastBackgroundDate)
                Logger.appLifecycleManager.debug("App进入.active状态, 距离上次非活跃 \(resumeAfter ?? -1)s")
            } else {
                resumeAfter = nil
                Logger.appLifecycleManager.debug("App进入.active状态")
            }
            eventSubject.send(.didBecomeActive(resumeAfter: resumeAfter))
        case .inactive:
            lastBackgroundDate = now
            Logger.appLifecycleManager.debug("App进入.inactive状态")
            eventSubject.send(.didBecomeInactive)
        case .background:
            Logger.appLifecycleManager.debug("App进入.background状态")
            eventSubject.send(.didEnterBackground)
        default:
            break
        }
    }
}
