//
//  OnboardingDormSetupPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/31.
//

import CSUSTKit
import GRDB
import SwiftUI

struct OnboardingDormSetupPage: View {
    @Bindable var viewModel: DormListViewModel

    private var primaryDorm: DormGRDB? {
        viewModel.dorms.first(where: \.isFavorite) ?? viewModel.dorms.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: primaryDorm == nil ? "building.2.crop.circle.badge.plus" : "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(primaryDorm == nil ? Color.accentColor : Color.green)
                        .padding(.top, 24)

                    Text(primaryDorm == nil ? "添加您的宿舍" : "宿舍已添加")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(
                        primaryDorm == nil
                            ? "绑定宿舍后，您可以查询宿舍电量，并继续配置后续的定时提醒。"
                            : "您已经完成宿舍添加，接下来可以继续配置宿舍定时通知。"
                    )
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
                    } else if let primaryDorm {
                        dormSummaryRow(for: primaryDorm)
                    } else {
                        Button(action: { viewModel.isAddDormSheetPresented = true }) {
                            Label("添加宿舍", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 8)
                    }

                    Text("您也可以稍后在“宿舍”页面继续管理宿舍信息。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $viewModel.isAddDormSheetPresented) {
            AddDormView(isPresented: $viewModel.isAddDormSheetPresented) { building, room in
                viewModel.addDormAndQuery(building: building, room: room)
            }
        }
        .errorToast($viewModel.errorToast)
    }

    @ViewBuilder
    private func dormSummaryRow(for dorm: DormGRDB) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.green)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(dorm.buildingName) \(dorm.room)")
                    .font(.headline)

                Text(dorm.campusName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("已添加 \(viewModel.dorms.count) 个宿舍")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
    }
}

extension DormListViewModel {
    func addDormAndQuery(building: CampusCardHelper.Building, room: String) {
        guard let dorm = insertDormForOnboarding(building: building, room: room) else { return }

        Task {
            await queryElectricity(for: dorm)
        }
    }

    @discardableResult
    private func insertDormForOnboarding(building: CampusCardHelper.Building, room: String) -> DormGRDB? {
        guard let pool = DatabaseManager.shared.pool else { return nil }

        do {
            return try pool.write { db in
                let duplicated =
                    try DormGRDB
                    .filter(DormGRDB.Columns.room == room)
                    .filter(DormGRDB.Columns.buildingID == building.id)
                    .fetchOne(db) != nil
                if duplicated {
                    errorToast.show(message: "该宿舍信息已存在")
                    return nil
                }

                var dorm = DormGRDB(
                    id: nil,
                    room: room,
                    buildingID: building.id,
                    buildingName: building.name,
                    campusID: building.campus.id,
                    campusName: building.campus.rawValue,
                    isFavorite: false,
                    lastFetchDate: nil,
                    lastFetchElectricity: nil,
                    scheduleHour: nil,
                    scheduleMinute: nil
                )
                try dorm.insert(db)
                return dorm
            }
        } catch {
            errorToast.show(message: error.localizedDescription)
            return nil
        }
    }
}
