//
//  AssignmentsContent.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/20.
//

import SwiftUI

struct AssignmentsContent: View {
    @State private var isNotificationSettingsPresented: Bool = false

    let courseGroups: [AssignmentsData]?

    let isLoading: Bool

    let isNotificationEnabled: Bool
    let notificationOffsetHour: Int
    let notificationOffsetMinute: Int

    @Binding var errorToast: ToastState
    @Binding var isNotificationDeniedAlertPresented: Bool

    let onRefreshAssignments: () async -> Void
    let onSaveNotificationSettings: (Bool, Int, Int) async -> Void
    let onOpenNotificationSettings: () -> Void

    private var submittableAssignmentsCount: Int {
        let referenceDate = Date.now
        return (courseGroups ?? []).reduce(0) { count, group in
            count + group.assignments.filter { $0.isSubmittable(referenceDate: referenceDate) }.count
        }
    }

    var body: some View {
        ListPageScaffold(
            title: "作业列表",
            subtitle: "共\(submittableAssignmentsCount)个可提交作业",
            isEmpty: courseGroups?.isEmpty ?? true,
            isLoading: isLoading,
            emptyNoun: "作业",
            errorToast: $errorToast,
            onQuery: onRefreshAssignments
        ) {
            ForEach(courseGroups ?? [], id: \.course.id) { group in
                AssignmentsCourseSection(group: group)
            }
        }
        .sheet(isPresented: $isNotificationSettingsPresented) {
            AssignmentsNotificationSettings(
                isEnabled: isNotificationEnabled,
                selectedHour: notificationOffsetHour,
                selectedMinute: notificationOffsetMinute,
                onSave: onSaveNotificationSettings
            )
            .presentationDetents([.medium, .large])
        }
        .alert("通知权限被拒绝", isPresented: $isNotificationDeniedAlertPresented) {
            Button(action: { isNotificationDeniedAlertPresented = false }) {
                Text("取消")
            }
            Button(action: onOpenNotificationSettings) {
                Text("前往设置")
            }
        } message: {
            Text("需要开启通知权限以接收作业提醒，请前往系统设置开启通知权限")
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: { isNotificationSettingsPresented = true }) {
                    Label("作业提醒设置", systemImage: "bell.badge")
                }
            }
        }
    }
}

#Preview("Normal") {
    NavigationStack {
        AssignmentsContent(
            courseGroups: MoocPreviewData.groups,
            isLoading: false,
            isNotificationEnabled: false,
            notificationOffsetHour: 8,
            notificationOffsetMinute: 20,
            errorToast: .constant(.errorTitle),
            isNotificationDeniedAlertPresented: .constant(false),
            onRefreshAssignments: {},
            onSaveNotificationSettings: { _, _, _ in },
            onOpenNotificationSettings: {}
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        AssignmentsContent(
            courseGroups: [],
            isLoading: false,
            isNotificationEnabled: false,
            notificationOffsetHour: 8,
            notificationOffsetMinute: 20,
            errorToast: .constant(.errorTitle),
            isNotificationDeniedAlertPresented: .constant(false),
            onRefreshAssignments: {},
            onSaveNotificationSettings: { _, _, _ in },
            onOpenNotificationSettings: {}
        )
    }
}
