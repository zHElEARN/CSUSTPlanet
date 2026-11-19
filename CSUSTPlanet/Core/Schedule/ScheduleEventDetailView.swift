//
//  ScheduleEventDetailView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/9/4.
//

import SwiftUI

struct ScheduleEventDetailView: View {
    let event: ScheduleEvent
    let onCustomEventSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editingEvent: CustomScheduleEventGRDB?
    @State private var confirmsDeletion = false
    @State private var isChanging = false
    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(event.kind.presentationTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(event.kind.presentationTint)

                    Text(event.content.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.leading)

                    if let subtitle = event.content.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let location = event.content.location, !location.isEmpty {
                        Text(location)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            Section("时间") {
                switch event.timing {
                case .interval(let start, let end):
                    LabeledContent("开始", value: formattedDate(start))
                    LabeledContent("结束", value: formattedDate(end))
                case .point(let at):
                    LabeledContent(
                        "截止",
                        value: ScheduleDateUtil.detailDateFormatter.string(from: at)
                    )
                }
            }

            if !event.content.details.isEmpty {
                Section("详细信息") {
                    ForEach(event.content.details, id: \.self) { detail in
                        LabeledContent(detail.label, value: detail.value)
                    }
                }
            }

            if event.kind == .custom {
                Section {
                    Button("删除日程", role: .destructive) {
                        confirmsDeletion = true
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("日程详情")
        .inlineToolbarTitle()
        .navigationDestination(item: $editingEvent) { record in
            CustomScheduleEventFormView(event: record, onSave: onCustomEventSaved)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
                .disabled(isChanging)
            }
            if event.kind == .custom {
                ToolbarItem(placement: .primaryAction) {
                    Button("编辑") { editCustomEvent(id: event.id) }
                        .disabled(isChanging)
                }
            }
        }
        .disabled(isChanging)
        .interactiveDismissDisabled(isChanging)
        .alert("删除日程", isPresented: $confirmsDeletion) {
            Button("删除", role: .destructive) {
                if event.kind == .custom {
                    deleteCustomEvent(id: event.id)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除「\(event.content.title)」吗？")
        }
        .errorToast($errorToast)
    }

    private func formattedDate(_ date: Date) -> String {
        let day = ScheduleDateUtil.detailDateFormatter.string(from: date)
        guard event.kind == .custom else { return day }
        return day + " " + ScheduleDateUtil.timeFormatter.string(from: date)
    }

    private func editCustomEvent(id: String) {
        isChanging = true
        Task {
            defer { isChanging = false }
            do {
                editingEvent = try await CustomScheduleEventRepository.fetch(id: id)
            } catch {
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    private func deleteCustomEvent(id: String) {
        isChanging = true
        Task {
            defer { isChanging = false }
            do {
                try await CustomScheduleEventRepository.delete(id: id)
                dismiss()
            } catch {
                errorToast.show(message: error.localizedDescription)
            }
        }
    }
}
