//
//  AvailableClassroomView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/8.
//

import CSUSTKit
import SwiftUI

struct AvailableClassroomView: View {
    @State private var schedule: ClassroomScheduleSnapshot?
    @State private var isLoading = false
    @State private var updatedAt: Date?
    @State private var errorToast: ToastState = .errorTitle

    init() {
        if let sessions = MMKVHelper.AvailableClassroom.cache {
            _schedule = State(initialValue: ClassroomScheduleSnapshot(sessions: sessions))
        }
    }

    var body: some View {
        AvailableClassroomContent(
            schedule: schedule,
            isLoading: isLoading,
            updatedAt: updatedAt,
            onQuery: queryClassrooms
        )
        .errorToast($errorToast)
    }

    private func queryClassrooms(campus: Campus) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // 获取整学期排课，所有时间和教室条件均在本地筛选。
            let result = try await AuthManager.shared.withAuthRetry(system: .edu) {
                try await AuthManager.shared.eduHelper.getClassroomSchedule(campus: campus)
            }
            MMKVHelper.AvailableClassroom.cache = result
            schedule = ClassroomScheduleSnapshot(sessions: result)
            updatedAt = .now
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}

extension MMKVHelper {
    enum AvailableClassroom {
        @MMKVOptionalStorage(key: "Cached.availableClassroomSchedule")
        static var cache: [EduHelper.ClassroomScheduleSession]?
    }
}
