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
    @State private var isResetAlertPresented = false
    #if os(macOS)
    @State private var targetedCard: OverviewCard?
    #endif

    var body: some View {
        Form {
            Section {
                #if os(macOS)
                ForEach(cardOrder, id: \.self) { card in
                    cardOrderRow(card)
                }
                #else
                ForEach(cardOrder, id: \.self) { card in
                    Label(card.title, systemImage: card.systemImage)
                }
                .onMove { fromOffsets, toOffset in
                    cardOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)
                }
                #endif
            } header: {
                Text("卡片顺序")
            } footer: {
                Text("拖动可调整卡片在概览页中的顺序")
            }

            Section {
                Toggle("自动排序（仅宽屏）", isOn: $isAutoSortEnabled)
            } header: {
                Text("布局")
            } footer: {
                Text("开启后，宽屏下按卡片高度自动排列（瀑布流）；关闭后按上方卡片顺序从左到右、从上到下依次排列。窄屏只有一列，始终按卡片顺序显示。")
            }
            .onChange(of: isAutoSortEnabled) { _, newValue in
                MMKVHelper.OverviewSettings.isAutoSortEnabled = newValue
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
        .alert("恢复默认设置", isPresented: $isResetAlertPresented) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive, action: resetToDefault)
        } message: {
            Text("将卡片顺序与自动排序开关恢复为默认设置。")
        }
    }

    #if os(macOS)
    private func cardOrderRow(_ card: OverviewCard) -> some View {
        HStack {
            Label(card.title, systemImage: card.systemImage)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
        }
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
        guard let source = cardOrder.firstIndex(of: dragged),
            let destination = cardOrder.firstIndex(of: target),
            source != destination
        else { return }

        withAnimation {
            cardOrder.move(fromOffsets: IndexSet(integer: source), toOffset: destination > source ? destination + 1 : destination)
        }
    }
    #endif

    private func resetToDefault() {
        withAnimation {
            cardOrder = OverviewCard.allCases
            isAutoSortEnabled = true
        }
    }
}
