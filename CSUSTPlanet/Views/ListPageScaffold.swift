//
//  ListPageScaffold.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/16.
//

import SwiftUI

struct ListPageScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let isEmpty: Bool
    let isLoading: Bool
    let emptyNoun: String
    let searchText: Binding<String>?
    let errorToast: Binding<ToastState>?
    let successToast: Binding<ToastState>?
    let loadingToast: Binding<ToastState>?
    let warningToast: Binding<ToastState>?
    let onQuery: () async -> Void
    let content: () -> Content

    init(
        title: String,
        subtitle: String? = nil,
        isEmpty: Bool,
        isLoading: Bool = false,
        emptyNoun: String,
        searchText: Binding<String>? = nil,
        errorToast: Binding<ToastState>? = nil,
        successToast: Binding<ToastState>? = nil,
        loadingToast: Binding<ToastState>? = nil,
        warningToast: Binding<ToastState>? = nil,
        onQuery: @escaping () async -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isEmpty = isEmpty
        self.isLoading = isLoading
        self.emptyNoun = emptyNoun
        self.searchText = searchText
        self.errorToast = errorToast
        self.successToast = successToast
        self.loadingToast = loadingToast
        self.warningToast = warningToast
        self.onQuery = onQuery
        self.content = content
    }

    var body: some View {
        Group {
            if isEmpty {
                if let searchText, !searchText.wrappedValue.isEmpty {
                    ContentUnavailableView.search(text: searchText.wrappedValue)
                } else {
                    ContentUnavailableView(
                        "暂无\(emptyNoun)信息",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("当前没有找到\(emptyNoun)信息")
                    )
                }
            } else {
                CustomScrollView {
                    LazyVStack(spacing: 16) {
                        content()
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .applyIfLet(searchText) { view, text in
            #if os(iOS)
            view.searchable(text: text, placement: .navigationBarDrawer(displayMode: .always))
            #elseif os(macOS)
            view.searchable(text: text, placement: .toolbar)
            #endif
        }
        .safeRefreshable { await onQuery() }
        .applyIfLet(errorToast) { view, toast in view.errorToast(toast) }
        .applyIfLet(successToast) { view, toast in view.successToast(toast) }
        .applyIfLet(loadingToast) { view, toast in view.loadingToast(toast) }
        .applyIfLet(warningToast) { view, toast in view.warningToast(toast) }
        .navigationTitle(title)
        .applyIfLet(subtitle) { view, subtitle in view.navigationSubtitleCompat(subtitle) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onQuery) {
                    if isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("查询", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoading)
            }
        }
    }
}
