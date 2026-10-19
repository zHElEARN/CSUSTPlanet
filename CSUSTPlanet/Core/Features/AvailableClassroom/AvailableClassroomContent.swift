//
//  AvailableClassroomContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import CSUSTKit
import SwiftUI

struct AvailableClassroomContent: View {
    let availableClassrooms: [String]?

    let isLoading: Bool

    @Binding var selectedCampus: CampusCardHelper.Campus
    @Binding var selectedWeek: Int
    @Binding var selectedDayOfWeek: EduHelper.DayOfWeek
    @Binding var selectedSection: Int

    @Binding var errorToast: ToastState

    let onQuery: () async -> Void

    @State private var searchText: String = ""

    private var filteredAvailableClassrooms: [String]? {
        guard let classrooms = availableClassrooms else { return nil }
        guard !searchText.isEmpty else { return classrooms }
        return classrooms.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let availableClassrooms = filteredAvailableClassrooms {
                if availableClassrooms.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "该时间段无空闲教室",
                            systemImage: "deskclock",
                            description: Text("可以更换周数、星期或节次后再试")
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                } else {
                    CustomScrollView {
                        resultsSection(availableClassrooms)
                            .padding()
                    }
                }
            } else {
                ContentUnavailableView(
                    "请先选择条件并查询",
                    systemImage: "magnifyingglass.circle",
                    description: Text("选择校区、周数、星期和节次后，点击下方「查询空教室」")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeRefreshable { await onQuery() }
        .safeAreaInset(edge: .top, spacing: 0) {
            filterBar
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            queryBar
        }
        #if os(iOS)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索查询结果")
        #elseif os(macOS)
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索查询结果")
        #endif
        .navigationTitle("空教室查询")
        .inlineToolbarTitle()
        .errorToast($errorToast)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                campusPicker
                weekPicker
                dayPicker
                sectionPicker
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    private var campusPicker: some View {
        filterChip(
            Picker("校区", selection: $selectedCampus) {
                ForEach(CampusCardHelper.Campus.allCases, id: \.self) { campus in
                    Text(campus.displayName).tag(campus)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        )
    }

    private var weekPicker: some View {
        filterChip(
            Picker("周数", selection: $selectedWeek) {
                ForEach(1...20, id: \.self) { week in
                    Text("第 \(week) 周").tag(week)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        )
    }

    private var dayPicker: some View {
        filterChip(
            Picker("星期", selection: $selectedDayOfWeek) {
                ForEach(EduHelper.DayOfWeek.allCases, id: \.self) { dayOfWeek in
                    Text(dayOfWeek.chineseLongString).tag(dayOfWeek)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        )
    }

    private var sectionPicker: some View {
        filterChip(
            Picker("节次", selection: $selectedSection) {
                ForEach(1...5, id: \.self) { section in
                    Text("第\(section)大节 (\(section * 2 - 1)-\(section * 2))").tag(section)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        )
    }

    private func filterChip<Content: View>(_ content: Content) -> some View {
        content
            .tint(.primary)
            .fixedSize()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .apply { view in
                if #available(iOS 26.0, macOS 26.0, *) {
                    view.glassEffect(.regular, in: .capsule)
                } else {
                    view.background(.ultraThinMaterial, in: Capsule())
                }
            }
    }

    // MARK: - Query Bar

    private var queryBar: some View {
        Button(asyncAction: onQuery) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(isLoading ? "查询中..." : "查询空教室")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
        }
        .apply { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
            } else {
                view
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(.capsule)
            }
        }
        .disabled(isLoading)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: 700)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Results Section

    @ViewBuilder
    private func resultsSection(_ availableClassrooms: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("查询结果", systemImage: "list.bullet.rectangle.portrait")
                    .font(.headline)
                Spacer()
                Text("共 \(availableClassrooms.count) 间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12
            ) {
                ForEach(availableClassrooms, id: \.self) { classroom in
                    CustomGroupBox {
                        Text(classroom)
                            .font(.callout)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

#Preview("未查询") {
    NavigationStack {
        AvailableClassroomContent(
            availableClassrooms: nil,
            isLoading: false,
            selectedCampus: .constant(.jinpenling),
            selectedWeek: .constant(1),
            selectedDayOfWeek: .constant(.monday),
            selectedSection: .constant(1),
            errorToast: .constant(.errorTitle),
            onQuery: {}
        )
    }
}

#Preview("无结果") {
    NavigationStack {
        AvailableClassroomContent(
            availableClassrooms: [],
            isLoading: false,
            selectedCampus: .constant(.jinpenling),
            selectedWeek: .constant(1),
            selectedDayOfWeek: .constant(.monday),
            selectedSection: .constant(1),
            errorToast: .constant(.errorTitle),
            onQuery: {}
        )
    }
}

#Preview("有结果") {
    NavigationStack {
        AvailableClassroomContent(
            availableClassrooms: AvailableClassroomPreviewData.classrooms,
            isLoading: false,
            selectedCampus: .constant(.jinpenling),
            selectedWeek: .constant(1),
            selectedDayOfWeek: .constant(.monday),
            selectedSection: .constant(1),
            errorToast: .constant(.errorTitle),
            onQuery: {}
        )
    }
}
