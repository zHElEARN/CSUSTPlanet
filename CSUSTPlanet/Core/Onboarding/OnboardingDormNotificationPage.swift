//
//  OnboardingDormNotificationPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import SwiftUI

struct OnboardingDormNotificationPage: View {
    @Bindable var viewModel: DormListViewModel
    @State private var selectedDormID: Int64?
    @State private var isScheduleConfigPresented = false

    private var selectedDorm: DormGRDB? {
        if let selectedDormID {
            return viewModel.dorms.first(where: { $0.id == selectedDormID })
        }
        return viewModel.dorms.first(where: \.scheduleEnabled) ?? viewModel.dorms.first(where: \.isFavorite) ?? viewModel.dorms.first
    }

    private var isSelectedDormQuerying: Bool {
        guard let selectedDorm else { return false }
        return viewModel.isQuerying(selectedDorm)
    }

    private var onboardingTitle: String {
        if viewModel.dorms.isEmpty {
            return "配置宿舍通知"
        }
        return selectedDorm?.scheduleEnabled == true ? "定时通知已开启" : "配置宿舍通知"
    }

    private var onboardingDescription: String {
        if viewModel.dorms.isEmpty {
            return "先添加一个宿舍，之后就可以为宿舍配置低电量定时提醒。"
        }
        if selectedDorm?.scheduleEnabled == true {
            return "当前宿舍已经完成定时通知配置，后续也可以随时调整提醒时间。"
        }
        return "选择一个宿舍，并为它设置每天的提醒时间。"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: selectedDorm?.scheduleEnabled == true ? "bell.badge.fill" : "bell.badge")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(selectedDorm?.scheduleEnabled == true ? Color.green : Color.accentColor)
                        .padding(.top, 24)

                    Text(onboardingTitle)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(onboardingDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 12)
                }

                VStack(spacing: 18) {
                    if viewModel.isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .smallControlSizeOnMac()

                            Text("正在读取宿舍信息...")
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    } else if viewModel.dorms.isEmpty {
                        Button(action: { viewModel.isAddDormSheetPresented = true }) {
                            Label("先添加宿舍", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 8)
                    } else {
                        dormPickerCard

                        if let selectedDorm, selectedDorm.scheduleEnabled {
                            scheduleSummaryRow(for: selectedDorm)
                        } else {
                            Button(action: handleConfigureButtonTapped) {
                                Label("配置宿舍定时通知", systemImage: "clock.badge")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.horizontal, 8)
                            .disabled(viewModel.isSchedulingDorm || selectedDorm == nil || isSelectedDormQuerying)

                            if isSelectedDormQuerying {
                                Text("正在刷新该宿舍的电量数据，完成后即可继续配置定时通知。")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            } else if let selectedDorm, !selectedDorm.hasFetchedElectricity {
                                Text("该宿舍还没有成功查询过电量，请先刷新一次电量后，再开启定时通知。")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Text("您也可以稍后在“宿舍”页面继续调整提醒时间。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { syncSelectedDorm(with: viewModel.dorms) }
        .onChange(of: viewModel.dorms) { _, newDorms in
            syncSelectedDorm(with: newDorms)
        }
        .sheet(isPresented: $viewModel.isAddDormSheetPresented) {
            AddDormView(isPresented: $viewModel.isAddDormSheetPresented) { building, room in
                viewModel.addDormAndQuery(building: building, room: room)
            }
        }
        .sheet(isPresented: $isScheduleConfigPresented) {
            if let selectedDorm {
                DormScheduleConfigView(
                    initialHour: selectedDorm.scheduleHour ?? 20,
                    initialMinute: selectedDorm.scheduleMinute ?? 0,
                    onConfirm: { hour, minute in
                        Task { await viewModel.configureSchedule(for: selectedDorm, hour: hour, minute: minute) }
                    },
                    isPresented: $isScheduleConfigPresented
                )
            }
        }
        .alert("通知权限被拒绝", isPresented: $viewModel.isNotificationDeniedAlertPresented) {
            Button(action: { viewModel.isNotificationDeniedAlertPresented = false }) {
                Text("取消")
            }
            Button(action: {
                NotificationManager.shared.openAppNotificationSettings()
                viewModel.isNotificationDeniedAlertPresented = false
            }) {
                Text("前往设置")
            }
        } message: {
            Text("需要开启通知权限以使用定时查询功能，请前往系统设置开启通知权限")
        }
        .errorToast($viewModel.errorToast)
    }

    private var dormPickerCard: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text("选择宿舍")
                        .font(.headline)

                    Spacer()

                    if let selectedDorm {
                        Button(asyncAction: { await viewModel.queryElectricity(for: selectedDorm) }) {
                            if viewModel.isQuerying(selectedDorm) {
                                ProgressView()
                                    .smallControlSizeOnMac()
                            } else {
                                Label("刷新电量", systemImage: "arrow.clockwise")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                Picker("宿舍", selection: $selectedDormID) {
                    ForEach(viewModel.dorms) { dorm in
                        Text("\(dorm.buildingName) \(dorm.room)")
                            .tag(dorm.id as Int64?)
                    }
                }
                .pickerStyle(.menu)

                if let selectedDorm {
                    Text(
                        isSelectedDormQuerying
                            ? "正在刷新该宿舍的最新电量。"
                            : selectedDorm.scheduleEnabled
                                ? "当前已配置为每天 \(formattedScheduleTime(for: selectedDorm)) 提醒。"
                                : "当前宿舍尚未开启定时通知。"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private func scheduleSummaryRow(for dorm: DormGRDB) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.green)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(dorm.buildingName) \(dorm.room)")
                    .font(.headline)

                Text("每天 \(formattedScheduleTime(for: dorm)) 提醒")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("宿舍定时通知已配置完成")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }

    private func handleConfigureButtonTapped() {
        guard let selectedDorm else { return }

        guard selectedDorm.hasFetchedElectricity else {
            viewModel.errorToast.show(message: "请先成功查询一次宿舍电量后再配置定时通知")
            return
        }

        isScheduleConfigPresented = true
    }

    private func syncSelectedDorm(with dorms: [DormGRDB]) {
        if let selectedDormID, dorms.contains(where: { $0.id == selectedDormID }) {
            return
        }

        selectedDormID =
            dorms.first(where: \.scheduleEnabled)?.id
            ?? dorms.first(where: \.isFavorite)?.id
            ?? dorms.first?.id
    }

    private func formattedScheduleTime(for dorm: DormGRDB) -> String {
        String(format: "%02d:%02d", dorm.scheduleHour ?? 20, dorm.scheduleMinute ?? 0)
    }
}
