import SwiftUI

struct ScheduleNotificationSettingsView: View {
    @Bindable private var coordinator = ScheduleNotificationCoordinator.shared

    @State private var isUpdatingEnablement = false
    @State private var isPermissionDeniedAlertPresented = false
    @State private var errorToast: ToastState = .errorTitle

    var body: some View {
        Form {
            Section {
                Toggle("日程通知总开关", isOn: isEnabledBinding)
                    .disabled(isUpdatingEnablement)
            }

            ForEach(ScheduleEventKind.allCases, id: \.self) { kind in
                Section {
                    let isEnabled = ruleBinding(for: kind, keyPath: \.isEnabled)
                    Toggle(kind.presentationTitle, isOn: isEnabled)
                    if isEnabled.wrappedValue {
                        Picker("提醒时间", selection: ruleBinding(for: kind, keyPath: \.leadTime)) {
                            ForEach(ScheduleNotificationLeadTime.allCases, id: \.self) { time in
                                Text(time.title).tag(time)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("日程通知")
        .inlineToolbarTitle()
        .errorToast($errorToast)
        .alert("通知权限被拒绝", isPresented: $isPermissionDeniedAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("前往设置") {
                NotificationManager.shared.openAppNotificationSettings()
            }
        } message: {
            Text("请在系统设置开启通知权限，然后回到 App 开启日程通知。")
        }
    }

    private var isEnabledBinding: Binding<Bool> {
        Binding {
            coordinator.isEnabled
        } set: { enabled in
            guard !isUpdatingEnablement else { return }
            isUpdatingEnablement = true
            Task {
                defer { isUpdatingEnablement = false }
                do {
                    let didSetEnabled = try await coordinator.setEnabledByUser(enabled)
                    isPermissionDeniedAlertPresented = !didSetEnabled
                } catch {
                    errorToast.show(message: error.localizedDescription)
                }
            }
        }
    }

    private func ruleBinding<Value>(for kind: ScheduleEventKind, keyPath: WritableKeyPath<ScheduleNotificationRule, Value>) -> Binding<Value> {
        Binding {
            coordinator.rule(for: kind)[keyPath: keyPath]
        } set: { value in
            var rule = coordinator.rule(for: kind)
            rule[keyPath: keyPath] = value
            coordinator.setRule(rule, for: kind)
        }
    }
}
