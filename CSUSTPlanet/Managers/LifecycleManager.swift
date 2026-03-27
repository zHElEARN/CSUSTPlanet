//
//  LifecycleManager.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/25.
//

import Combine
import Foundation
import SwiftUI

#if os(macOS)
import AppKit
#endif

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

    private var cancellables = Set<AnyCancellable>()

    private init() {
        #if os(macOS)
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                self?.lastBackgroundDate = Date()
                self?.eventSubject.send(.didBecomeInactive)
            }
            .store(in: &cancellables)
        #endif
    }

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
        scenePhaseSubject.send(newPhase)

        switch newPhase {
        case .active:
            handleAppDidBecomeActive()
        case .inactive:
            lastBackgroundDate = Date()
            eventSubject.send(.didBecomeInactive)
        case .background:
            eventSubject.send(.didEnterBackground)
        default:
            break
        }
    }

    // MARK: - Helper

    private func handleAppDidBecomeActive() {
        let now = Date()
        let resumeAfter: TimeInterval?

        if isFirstAppearance {
            resumeAfter = nil
            isFirstAppearance = false
            return
        } else if let lastBackgroundDate {
            resumeAfter = now.timeIntervalSince(lastBackgroundDate)
        } else {
            resumeAfter = nil
        }

        eventSubject.send(.didBecomeActive(resumeAfter: resumeAfter))
    }
}
