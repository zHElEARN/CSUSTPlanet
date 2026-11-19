import SwiftUI

struct CustomScheduleEventFormView: View {
    let isNew: Bool
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var event: CustomScheduleEventGRDB
    @State private var day: Date
    @State private var location: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorToast: ToastState = .errorTitle

    init(onSave: @escaping () -> Void) {
        let calendar = ScheduleDateUtil.calendar
        let today = calendar.startOfDay(for: .now)
        let startDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today
        let endDate = startDate.addingTimeInterval(3600)
        let event = CustomScheduleEventGRDB(title: "", startDate: startDate, endDate: endDate)
        self.init(event: event, isNew: true, onSave: onSave)
    }

    init(event: CustomScheduleEventGRDB, isNew: Bool = false, onSave: @escaping () -> Void) {
        self.isNew = isNew
        self.onSave = onSave
        _event = State(initialValue: event)
        _day = State(initialValue: event.startDate)
        _location = State(initialValue: event.location ?? "")
        _notes = State(initialValue: event.notes ?? "")
    }

    var body: some View {
        Form {
            Section("日程信息") {
                TextField("标题（必填）", text: $event.title)
                TextField("地点（选填）", text: $location)
                TextField("备注（选填）", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section("时间") {
                DatePicker("日期", selection: $day, displayedComponents: .date)
                DatePicker("开始", selection: $event.startDate, displayedComponents: .hourAndMinute)
                DatePicker("结束", selection: $event.endDate, displayedComponents: .hourAndMinute)
            }
        }
        .formStyle(.grouped)
        .environment(\.calendar, ScheduleDateUtil.calendar)
        .environment(\.timeZone, ScheduleDateUtil.calendar.timeZone)
        .navigationTitle(isNew ? "新建日程" : "编辑日程")
        .inlineToolbarTitle()
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isSaving)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存", action: save)
                    .disabled(isSaving)
            }
        }
        .disabled(isSaving)
        .interactiveDismissDisabled(isSaving)
        .errorToast($errorToast)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 380)
        #endif
    }

    private func save() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                var draft = event
                draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                draft.startDate = try date(on: day, withTimeFrom: draft.startDate)
                draft.endDate = try date(on: day, withTimeFrom: draft.endDate)
                draft.location = location.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                draft.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                try await CustomScheduleEventRepository.save(draft, isNew: isNew)
                onSave()
            } catch {
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    private func date(on day: Date, withTimeFrom time: Date) throws -> Date {
        let calendar = ScheduleDateUtil.calendar
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = calendar.component(.hour, from: time)
        components.minute = calendar.component(.minute, from: time)
        guard let date = calendar.date(from: components) else {
            throw CustomScheduleEventError.invalidTimeRange
        }
        return date
    }
}
