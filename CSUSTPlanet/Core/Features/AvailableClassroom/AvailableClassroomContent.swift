//
//  AvailableClassroomContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import CSUSTKit
import SwiftUI

struct AvailableClassroomContent: View {
    let schedule: ClassroomScheduleSnapshot?
    let isLoading: Bool
    let updatedAt: Date?
    let onQuery: (Campus) async -> Void

    @State private var selectedWeek = 1
    @State private var selectedDay = CourseScheduleUtil.getDayOfWeek(.now)
    @State private var startSection = 1
    @State private var endSection = 2
    @State private var searchText = ""
    @State private var showsOccupied = false
    @State private var isFilterPresented = false
    @State private var selectedRoom: ClassroomAvailability?

    private var sectionCount: Int { schedule?.sectionCount ?? 10 }
    private var weekCount: Int { schedule?.weekCount ?? 20 }
    private var selection: ClosedRange<Int> { min(startSection, endSection)...max(startSection, endSection) }

    private var rooms: [ClassroomAvailability] {
        schedule?.rooms(week: selectedWeek, day: selectedDay) ?? []
    }

    private func visibleRooms(in rooms: [ClassroomAvailability]) -> [ClassroomAvailability] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return rooms.filter {
            (showsOccupied || $0.isAvailable(during: selection))
                && (query.isEmpty || $0.id.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        let rooms = rooms
        let visibleRooms = visibleRooms(in: rooms)
        return Group {
            if visibleRooms.isEmpty {
                VStack(spacing: 0) {
                    if !rooms.isEmpty {
                        scopePicker
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .frame(maxWidth: 860)
                    }
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ContentUnavailableView.search(text: searchText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView(
                            "暂无教室信息",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("当前没有找到教室信息")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                ScrollView {
                    results(rooms, visibleRooms: visibleRooms)
                        .padding(20)
                        .frame(maxWidth: 860)
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, spacing: 0) {
            timeFilterHeader
        }
        .navigationTitle("空教室查询")
        .inlineToolbarTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach([Campus.jinpenling, .yuntang], id: \.self) { campus in
                        Button(asyncAction: { await onQuery(campus) }) {
                            Label("加载\(campus.displayName)课表", systemImage: "arrow.clockwise")
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .disabled(isLoading)
            }
        }
        #if os(iOS)
        .searchable(text: $searchText.withAnimation(), placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索教室名称")
        .scrollDismissesKeyboard(.interactively)
        #else
        .searchable(text: $searchText.withAnimation(), placement: .toolbar, prompt: "搜索教室名称")
        #endif
        .sheet(isPresented: $isFilterPresented) {
            ClassroomTimeFilterView(
                selectedWeek: $selectedWeek, selectedDay: $selectedDay,
                startSection: $startSection, endSection: $endSection,
                weekCount: weekCount, sectionCount: sectionCount
            )
            #if os(iOS)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            #else
            .frame(minWidth: 380, minHeight: 340)
            #endif
        }
        .onChange(of: startSection) { _, value in
            if endSection < value { withAnimation { endSection = value } }
        }
        .onChange(of: endSection) { _, value in
            if startSection > value { withAnimation { startSection = value } }
        }
        .onChange(of: sectionCount) { _, value in
            endSection = min(endSection, value)
            startSection = min(startSection, value)
        }
        .sheet(item: $selectedRoom) { room in
            ClassroomAvailabilityDetail(
                room: room, selection: selection, weekCount: weekCount,
                week: selectedWeek, day: selectedDay
            )
        }
    }

    private var timeFilterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button {
                    isFilterPresented = true
                } label: {
                    timeFilterChip("筛选", systemImage: "line.3.horizontal.decrease")
                }
                .buttonStyle(.plain)

                Menu {
                    Picker("周次", selection: $selectedWeek.withAnimation()) {
                        ForEach(1...weekCount, id: \.self) { Text("第 \($0) 周").tag($0) }
                    }
                } label: {
                    timeFilterChip("第 \(selectedWeek) 周", showsChevron: true)
                }
                .buttonStyle(.plain)
                .tint(.primary)
                Menu {
                    Picker("星期", selection: $selectedDay.withAnimation()) {
                        ForEach(ClassroomAvailability.weekdays, id: \.self) { Text($0.chineseLongString).tag($0) }
                    }
                } label: {
                    timeFilterChip(selectedDay.chineseLongString, showsChevron: true)
                }
                .buttonStyle(.plain)
                .tint(.primary)
                Menu {
                    Menu("开始节次") {
                        Picker("开始节次", selection: $startSection.withAnimation()) {
                            ForEach(1...sectionCount, id: \.self) { Text("第 \($0) 节").tag($0) }
                        }
                    }
                    Menu("结束节次") {
                        Picker("结束节次", selection: $endSection.withAnimation()) {
                            ForEach(1...sectionCount, id: \.self) { Text("第 \($0) 节").tag($0) }
                        }
                    }
                } label: {
                    timeFilterChip(ClassroomAvailability.sectionLabel(selection), showsChevron: true)
                }
                .buttonStyle(.plain)
                .tint(.primary)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.bar)
    }

    private func timeFilterChip(_ title: String, systemImage: String? = nil, showsChevron: Bool = false) -> some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .foregroundColor(.primary)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.secondary.opacity(0.14), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func results(_ rooms: [ClassroomAvailability], visibleRooms: [ClassroomAvailability]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                scopePicker
                Text("\(visibleRooms.count) 间\(showsOccupied ? "教室" : "空闲教室")")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text("当天节次：绿色为空闲，红色为有课，蓝色描边为查询范围。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 280), spacing: 16, alignment: .top)],
                alignment: .leading, spacing: 16
            ) {
                ForEach(visibleRooms) { room in
                    Button {
                        selectedRoom = room
                    } label: {
                        classroomCard(room)
                    }
                    .buttonStyle(.plain)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("本校区共 \(rooms.count) 间教室")
                if let updatedAt {
                    Text("课表更新于 \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                Text("空闲情况依据本学期课表计算，实际开放情况以现场为准。")
            }
            .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var scopePicker: some View {
        Picker("显示范围", selection: $showsOccupied.withAnimation()) {
            Text("仅空闲教室").tag(false)
            Text("全部教室").tag(true)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    private func availabilitySummary(_ room: ClassroomAvailability) -> String {
        guard let range = room.freeRange(containing: selection) else { return "所选时段有课程" }
        return range == 1...room.sectionCount ? "全天空闲" : "\(ClassroomAvailability.sectionLabel(range))连续空闲"
    }

    private func classroomCard(_ room: ClassroomAvailability) -> some View {
        let isFree = room.isAvailable(during: selection)
        return CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(room.id).font(.headline).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Label(isFree ? "空闲" : "有课", systemImage: isFree ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.caption).foregroundStyle(isFree ? Color.green : Color.red)
                        .fixedSize()
                }
                Text(availabilitySummary(room))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ClassroomSectionStrip(room: room, selection: selection, showsSectionNumbers: true)
                HStack(alignment: .firstTextBaseline) {
                    Text("当天 \(room.freeSectionCount) 节空闲")
                    Spacer()
                    HStack(spacing: 4) {
                        Text("查看详细")
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold))
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .contentShape(.rect)
        }
    }
}

/// 使用单行等宽节次条，避免嵌套自适应网格在 Mac 上换行、错位。
struct ClassroomSectionStrip: View {
    let room: ClassroomAvailability
    var selection: ClosedRange<Int>?
    var showsLabels = false
    var showsSectionNumbers = false
    @Environment(\.colorScheme) private var colorScheme

    private var selectionColor: Color {
        colorScheme == .dark ? Color(red: 0.4, green: 0.75, blue: 1) : .blue
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...room.sectionCount, id: \.self) { section in
                let occupied = room.occupiedSections.contains(section)
                VStack(spacing: 6) {
                    if showsLabels || showsSectionNumbers {
                        Text("\(section)")
                            .font(.caption2).monospacedDigit()
                            .foregroundStyle(selection?.contains(section) == true ? selectionColor : Color.secondary)
                    }
                    Capsule()
                        .fill(occupied ? Color.red.opacity(0.7) : Color.green.opacity(0.75))
                        .frame(height: 6)
                        .padding(3)
                        .overlay {
                            if selection?.contains(section) == true {
                                Capsule().strokeBorder(selectionColor, lineWidth: 2)
                            }
                        }
                    if showsLabels {
                        Text(occupied ? "课" : "空")
                            .font(.caption2).foregroundStyle(occupied ? Color.secondary : Color.green)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
