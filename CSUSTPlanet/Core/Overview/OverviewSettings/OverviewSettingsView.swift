//
//  OverviewSettingsView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/23.
//

import SwiftUI

struct OverviewSettingsView: View {
    @State private var isAutoSortEnabled = MMKVHelper.OverviewSettings.isAutoSortEnabled
    @State private var cardOrder = MMKVHelper.OverviewSettings.orderedCards
    @State private var hiddenCards = MMKVHelper.OverviewSettings.hiddenCards
    @State private var isResetAlertPresented = false
    @State private var isGradeHidden = MMKVHelper.OverviewSettings.isGradeHidden
    @State private var isDormHidden = MMKVHelper.OverviewSettings.isDormHidden
    #if os(macOS)
    @State private var targetedCard: OverviewCard?
    #endif

    private var visibleCards: [OverviewCard] {
        cardOrder.filter { !hiddenCards.contains($0) }
    }

    private var hiddenCardsList: [OverviewCard] {
        OverviewCard.allCases.filter { hiddenCards.contains($0) }
    }

    var body: some View {
        Form {
            Section {
                if visibleCards.isEmpty {
                    Text("暂无显示的卡片")
                        .foregroundStyle(.secondary)
                } else {
                    #if os(macOS)
                    ForEach(visibleCards, id: \.self) { card in
                        cardOrderRow(card)
                    }
                    #else
                    ForEach(visibleCards, id: \.self) { card in
                        cardRowContent(card, isHidden: false, showDragHandle: false)
                    }
                    .onMove { fromOffsets, toOffset in
                        var updated = visibleCards
                        updated.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        cardOrder = updated + hiddenCardsList
                    }
                    #endif
                }
            } header: {
                Text("卡片顺序")
            } footer: {
                Text("拖动可调整卡片在概览页中的顺序，点击眼睛图标可隐藏卡片")
            }

            if !hiddenCardsList.isEmpty {
                Section {
                    ForEach(hiddenCardsList, id: \.self) { card in
                        cardRowContent(card, isHidden: true, showDragHandle: false)
                    }
                } header: {
                    Text("已隐藏的卡片")
                } footer: {
                    Text("点击眼睛图标可恢复显示，并回到默认位置")
                }
            }

            Section {
                Toggle("自动排序（仅宽屏）", isOn: $isAutoSortEnabled)
            } header: {
                Text("布局")
            } footer: {
                Text("开启后，宽屏下按卡片高度自动排列（瀑布流）；关闭后按上方卡片顺序从左到右、从上到下依次排列。窄屏只有一列，始终按卡片顺序显示。")
            }

            Section {
                Toggle("隐藏成绩", isOn: $isGradeHidden)
                Toggle("隐藏宿舍电量", isOn: $isDormHidden)
            } header: {
                Text("隐私")
            } footer: {
                Text("开启后，成绩查询卡片将隐藏 GPA、平均分与成绩趋势图；宿舍电量卡片将隐藏房间号、电量数值与电量趋势图。")
            }

            Section {
                Button("恢复默认设置", role: .destructive) {
                    isResetAlertPresented = true
                }
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .environment(\.editMode, .constant(.active))
        #endif
        .navigationTitle("概览设置")
        .onChange(of: cardOrder) { _, newValue in
            MMKVHelper.OverviewSettings.orderedCards = newValue
        }
        .onChange(of: hiddenCards) { _, newValue in
            MMKVHelper.OverviewSettings.hiddenCards = newValue
        }
        .onChange(of: isAutoSortEnabled) { _, newValue in
            MMKVHelper.OverviewSettings.isAutoSortEnabled = newValue
        }
        .onChange(of: isGradeHidden) { _, newValue in
            MMKVHelper.OverviewSettings.isGradeHidden = newValue
        }
        .onChange(of: isDormHidden) { _, newValue in
            MMKVHelper.OverviewSettings.isDormHidden = newValue
        }
        .onReceive(MMKVHelper.OverviewSettings.$isGradeHidden) { newValue in
            isGradeHidden = newValue
        }
        .onReceive(MMKVHelper.OverviewSettings.$isDormHidden) { newValue in
            isDormHidden = newValue
        }
        .alert("恢复默认设置", isPresented: $isResetAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive, action: resetToDefault)
        } message: {
            Text("将卡片顺序、卡片显示状态、自动排序、隐藏成绩与隐藏宿舍电量恢复为默认设置。")
        }
    }

    @ViewBuilder
    private func cardRowContent(_ card: OverviewCard, isHidden: Bool, showDragHandle: Bool) -> some View {
        HStack {
            Label(card.title, systemImage: card.systemImage)
                .foregroundStyle(isHidden ? .secondary : .primary)

            Spacer()

            Button {
                toggleVisibility(for: card)
            } label: {
                Image(systemName: isHidden ? "eye.slash" : "eye")
                    .foregroundStyle(isHidden ? .secondary : .primary)
            }
            .buttonStyle(.borderless)

            if showDragHandle {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func toggleVisibility(for card: OverviewCard) {
        withAnimation {
            if hiddenCards.contains(card) {
                var updatedVisible = visibleCards
                hiddenCards.remove(card)
                let defaultIndex = OverviewCard.allCases.firstIndex(of: card) ?? updatedVisible.count
                let targetIndex = min(defaultIndex, updatedVisible.count)
                updatedVisible.insert(card, at: targetIndex)
                cardOrder = updatedVisible + hiddenCardsList
            } else {
                hiddenCards.insert(card)
                cardOrder = visibleCards + hiddenCardsList
            }
        }
    }

    private func resetToDefault() {
        withAnimation {
            cardOrder = OverviewCard.allCases
            hiddenCards = []
            isAutoSortEnabled = true
            isGradeHidden = false
            isDormHidden = false
        }
    }

    #if os(macOS)
    private func cardOrderRow(_ card: OverviewCard) -> some View {
        cardRowContent(card, isHidden: false, showDragHandle: true)
            .contentShape(.rect)
            .draggable(card.rawValue) {
                Label(card.title, systemImage: card.systemImage)
            }
            .dropDestination(for: String.self) { items, _ in
                guard let rawValue = items.first, let dragged = OverviewCard(rawValue: rawValue) else { return false }
                moveCard(dragged, to: card)
                return true
            } isTargeted: { isTargeted in
                withAnimation {
                    targetedCard = isTargeted ? card : (targetedCard == card ? nil : targetedCard)
                }
            }
            .background(targetedCard == card ? Color.accentColor.opacity(0.15) : .clear, in: .rect(cornerRadius: 3))
    }

    private func moveCard(_ dragged: OverviewCard, to target: OverviewCard) {
        var updated = visibleCards
        guard let source = updated.firstIndex(of: dragged),
            let destination = updated.firstIndex(of: target),
            source != destination
        else { return }

        withAnimation {
            updated.move(fromOffsets: IndexSet(integer: source), toOffset: destination > source ? destination + 1 : destination)
            cardOrder = updated + hiddenCardsList
        }
    }
    #endif
}
