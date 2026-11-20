import SwiftUI

struct CalendarExportSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var accounts: [CalendarUtil.EventAccount] = []
    @State private var selectedAccountID: String?
    @State private var isLoadingAccounts = true
    @State private var isExporting = false
    @State private var errorToast: ToastState = .errorTitle

    let onExport: (String) async throws -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isLoadingAccounts {
                        VStack(spacing: 8) {
                            ProgressView().smallControlSizeOnMac()
                            Text("正在读取日历账户")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)
                    }
                    ForEach(accounts) { account in
                        let isSelected = selectedAccountID == account.id
                        Button {
                            selectedAccountID = account.id
                            errorToast.hide()
                        } label: {
                            HStack {
                                Text(account.title)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(isExporting)
            .navigationTitle("选择日历账户")
            .inlineToolbarTitle()
            .errorToast($errorToast)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(isExporting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(asyncAction: export) {
                        if isExporting {
                            ProgressView().smallControlSizeOnMac()
                        } else {
                            Text("确认添加")
                        }
                    }
                    .disabled(selectedAccountID == nil || isExporting)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(isExporting)
        .task {
            defer { isLoadingAccounts = false }
            do {
                accounts = try await CalendarUtil.shared.eventAccounts()
            } catch {
                errorToast.show(message: error.localizedDescription)
            }
        }
    }

    private func export() async {
        guard let selectedAccountID, !isExporting else { return }
        isExporting = true
        errorToast.hide()
        defer { isExporting = false }

        do {
            try await onExport(selectedAccountID)
            dismiss()
        } catch {
            errorToast.show(message: error.localizedDescription)
        }
    }
}
