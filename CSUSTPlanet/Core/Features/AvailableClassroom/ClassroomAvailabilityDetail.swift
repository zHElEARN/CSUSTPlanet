//
//  ClassroomAvailabilityDetail.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/11/11.
//

import CSUSTKit
import SwiftUI

struct ClassroomAvailabilityDetail: View {
    enum Scope: String, CaseIterable {
        case day = "当天"
        case week = "本周"
        case semester = "本学期总览"
    }

    let room: ClassroomAvailability
    let selection: ClosedRange<Int>
    let weekCount: Int
    @State var week: Int
    @State var day: DayOfWeek
    @State var scope: Scope = .day
    @Environment(\.dismiss) private var dismiss

    private var dailyRoom: ClassroomAvailability { room.on(week: week, day: day) }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if scope != .semester {
                            dateControls
                        }
                        switch scope {
                        case .day: dailySchedule
                        case .week: weeklySchedule
                        case .semester: semesterSchedule
                        }
                        Text("空闲情况依据教务课表计算，实际开放情况以现场为准。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .id("scheduleTop")
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    Picker("课表范围", selection: $scope.withAnimation()) {
                        ForEach(Scope.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .padding()
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
                }
                .onChange(of: scope) { _, _ in proxy.scrollTo("scheduleTop", anchor: .top) }
                .onChange(of: day) { _, _ in proxy.scrollTo("scheduleTop", anchor: .top) }
                .onChange(of: week) { _, _ in proxy.scrollTo("scheduleTop", anchor: .top) }
            }
            .navigationTitle(room.id)
            #if os(iOS)
            .navigationSubtitleCompat("本学期 \(room.allSessions.count) 项排课")
            #endif
            .inlineToolbarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, idealWidth: 600, minHeight: 480, idealHeight: 660)
        #endif
    }

    private var dateControls: some View {
        HStack {
            Picker("周次", selection: $week.withAnimation()) {
                ForEach(1...weekCount, id: \.self) { Text("第 \($0) 周").tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            Spacer()
            if scope == .day {
                Picker("星期", selection: $day.withAnimation()) {
                    ForEach(ClassroomAvailability.weekdays, id: \.self) { Text($0.chineseLongString).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
            }
        }
        .pickerStyle(.menu)
    }

    private var dailySchedule: some View {
        let daily = dailyRoom
        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("当天概览", detail: "\(daily.freeSectionCount) 节空闲")
                CustomGroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        ClassroomSectionStrip(room: daily, selection: selection, showsLabels: true)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("空闲时段")
                CustomGroupBox {
                    VStack(spacing: 12) {
                        if daily.freeRanges.isEmpty {
                            Text("当天没有空闲节次").foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(daily.freeRanges, id: \.lowerBound) { range in
                                HStack(alignment: .firstTextBaseline) {
                                    Label(ClassroomAvailability.sectionLabel(range), systemImage: "checkmark.circle")
                                        .foregroundStyle(.green)
                                    Spacer(minLength: 8)
                                    if let time = ClassroomAvailability.timeLabel(range) {
                                        Text(time).foregroundStyle(.secondary).monospacedDigit()
                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading("课程安排", detail: "\(daily.sessions.count) 项")
                if daily.sessions.isEmpty {
                    CustomGroupBox {
                        Label("当天无课程安排", systemImage: "calendar.badge.checkmark")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    CustomGroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(daily.sessions.enumerated()), id: \.offset) { index, session in
                                if index > 0 { Divider() }
                                sessionRow(session)
                            }
                        }
                    }
                }
            }
        }
    }

    private var weeklySchedule: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading("第 \(week) 周课表", detail: "点击查看当天")
            ForEach(ClassroomAvailability.weekdays, id: \.self) { weekday in
                let daily = room.on(week: week, day: weekday)
                Button {
                    withAnimation {
                        day = weekday
                        scope = .day
                    }
                } label: {
                    CustomGroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(weekday.chineseLongString).font(.headline).foregroundStyle(.primary)
                                Spacer()
                                Text("\(daily.freeSectionCount) 节空闲").font(.subheadline).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                            }
                            ClassroomSectionStrip(room: daily, showsLabels: true)
                        }
                        .contentShape(.rect)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var semesterSchedule: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(ClassroomAvailability.weekdays, id: \.self) { weekday in
                let sessions = room.allSessions.filter { $0.dayOfWeek == weekday }.sorted(by: ClassroomAvailability.sessionOrder)
                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeading(weekday.chineseLongString)
                        CustomGroupBox {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(sessions.enumerated()), id: \.offset) { index, session in
                                    if index > 0 { Divider() }
                                    sessionRow(session, showsWeeks: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeading(_ title: String, detail: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.headline)
            Spacer()
            if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func sessionRow(_ session: EduHelper.ClassroomScheduleSession, showsWeeks: Bool = false) -> some View {
        let range = session.startSection...session.endSection
        return VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(ClassroomAvailability.sectionLabel(range)).fontWeight(.medium)
                    Spacer(minLength: 8)
                    if let time = ClassroomAvailability.timeLabel(range) {
                        Text(time).foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                Text(ClassroomAvailability.sectionLabel(range)).fontWeight(.medium)
            }
            .font(.subheadline)
            Text(session.courseLabel)
                .font(.body).textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if showsWeeks {
                Text(ClassroomAvailability.weeksLabel(session.weeks))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
