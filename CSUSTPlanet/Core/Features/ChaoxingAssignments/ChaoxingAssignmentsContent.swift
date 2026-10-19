//
//  ChaoxingAssignmentsContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import CSUSTKit
import SwiftUI

struct ChaoxingAssignmentsContent: View {
    let assignments: [ChaoxingHelper.Assignment]?

    let isLoading: Bool

    @Binding var errorToast: ToastState

    let onRefreshAssignments: () async -> Void

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #else
    @State private var presentedDetailURL: URL?
    #endif

    @State private var pendingDetailURL: URL?

    private var assignmentCount: Int {
        assignments?.count ?? 0
    }

    private var uncompletedCount: Int {
        assignments?.filter { !$0.isCompleted }.count ?? 0
    }

    /// 未完成作业按截止时间升序排在前面，已完成作业保持接口原顺序排在后面
    private var sortedAssignments: [ChaoxingHelper.Assignment] {
        let allAssignments = assignments ?? []
        let uncompletedAssignments = allAssignments.filter { !$0.isCompleted }
        let completedAssignments = allAssignments.filter { $0.isCompleted }

        let sortedUncompletedAssignments = uncompletedAssignments.enumerated()
            .sorted { lhs, rhs in
                let lhsDeadline = lhs.element.deadline
                let rhsDeadline = rhs.element.deadline

                if let lhsDeadline, let rhsDeadline, lhsDeadline != rhsDeadline {
                    return lhsDeadline < rhsDeadline
                }
                if lhsDeadline == nil, rhsDeadline != nil {
                    return false
                }
                if lhsDeadline != nil, rhsDeadline == nil {
                    return true
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)

        return sortedUncompletedAssignments + completedAssignments
    }

    var body: some View {
        ListPageScaffold(
            title: "学习通作业",
            subtitle: "共\(assignmentCount)个作业，\(uncompletedCount)个未完成",
            isEmpty: sortedAssignments.isEmpty,
            isLoading: isLoading,
            emptyNoun: "学习通作业",
            errorToast: $errorToast,
            onQuery: onRefreshAssignments
        ) {
            ForEach(sortedAssignments, id: \.self) { assignment in
                ChaoxingAssignmentCard(assignment: assignment, onRequestOpen: { pendingDetailURL = $0 })
            }
        }
        .alert("提交作业风险提示", isPresented: isDisclaimerPresented, presenting: pendingDetailURL) { url in
            Button("取消", role: .cancel) {
                pendingDetailURL = nil
            }
            Button("仍要打开", role: .destructive) {
                presentDetail(url)
            }
        } message: { _ in
            Text("应用内网页并非学习通官方App，作业可能提交失败或者错误提交，本应用无法保证正确提交作业。建议点击工具栏的「打开学习通」，前往官方学习通App中提交作业。")
        }
        #if os(iOS)
        .sheet(isPresented: isDetailSheetPresented) {
            if let presentedDetailURL {
                NavigationStack {
                    ChaoxingAssignmentDetailView(detailURL: presentedDetailURL)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                self.presentedDetailURL = nil
                            }
                        }
                    }
                }
            }
        }
        #endif
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Button(action: openChaoxingApp) {
                    Label("打开学习通", systemImage: "arrow.up.forward.app")
                }
            }
        }
    }

    private var isDisclaimerPresented: Binding<Bool> {
        Binding(
            get: { pendingDetailURL != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDetailURL = nil
                }
            }
        )
    }

    private func presentDetail(_ url: URL) {
        pendingDetailURL = nil
        #if os(macOS)
        openWindow(id: ChaoxingAssignmentDetailScene.windowID, value: url)
        #else
        presentedDetailURL = url
        #endif
    }

    #if os(iOS)
    private var isDetailSheetPresented: Binding<Bool> {
        Binding(
            get: { presentedDetailURL != nil },
            set: { isPresented in
                if !isPresented {
                    presentedDetailURL = nil
                }
            }
        )
    }
    #endif

    private func openChaoxingApp() {
        #if os(iOS)
        guard let url = URL(string: "cxStudy://") else { return }
        PlatformApplication.shared.open(url) { success in
            if !success {
                errorToast.show(message: "打开失败，请检查是否已安装学习通")
            }
        }
        #else
        errorToast.show(message: "macOS 暂不支持打开学习通")
        #endif
    }
}

#Preview("Normal") {
    NavigationStack {
        ChaoxingAssignmentsContent(
            assignments: ChaoxingAssignmentsPreviewData.assignments,
            isLoading: false,
            errorToast: .constant(.errorTitle),
            onRefreshAssignments: {}
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        ChaoxingAssignmentsContent(
            assignments: [],
            isLoading: false,
            errorToast: .constant(.errorTitle),
            onRefreshAssignments: {}
        )
    }
}
