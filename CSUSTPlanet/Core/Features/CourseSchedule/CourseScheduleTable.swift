//
//  CourseScheduleTable.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleTable: View {
    let semesterStartDate: Date
    let targetWeek: Int
    let weeklyCourses: [Int: [CourseOccurrence]]
    let courseColors: [String: Color]

    @Binding var isCourseDetailInspectorPresented: Bool
    @Binding var selectedCourseInfo: CourseOccurrence?

    @Environment(\.courseScheduleLayoutConfig) private var layoutConfig

    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                backgroundGrid

                CourseScheduleOverlay(
                    targetWeek: targetWeek,
                    weeklyCourses: weeklyCourses,
                    courseColors: courseColors,
                    isCourseDetailInspectorPresented: $isCourseDetailInspectorPresented,
                    selectedCourseInfo: $selectedCourseInfo,
                )
            }
        }
        .safeAreaInset(edge: .top) {
            header
        }
    }

    @ViewBuilder
    private var backgroundGrid: some View {
        HStack(spacing: layoutConfig.colSpacing) {
            // 左侧时间列
            VStack(spacing: layoutConfig.rowSpacing) {
                ForEach(1...ScheduleUtils.sectionTimeStrings.count, id: \.self) { section in
                    VStack(spacing: 1) {
                        Text("\(section)")
                            .font(.system(size: layoutConfig.isWideSize ? 18 : 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            Text(ScheduleUtils.sectionTimeStrings[section - 1].start)
                            Text(ScheduleUtils.sectionTimeStrings[section - 1].end)
                        }
                        .font(.system(size: layoutConfig.isWideSize ? 12 : 9))
                        .foregroundColor(.secondary)
                    }
                    .frame(width: layoutConfig.timeColWidth, height: layoutConfig.sectionHeight)
                }
            }

            VStack(spacing: layoutConfig.rowSpacing) {
                ForEach(ScheduleUtils.sectionTimeStrings.indices, id: \.self) { _ in
                    HStack(spacing: layoutConfig.colSpacing) {
                        ForEach(1...7, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.primary.opacity(0.04))
                                .frame(height: layoutConfig.sectionHeight)
                                .cornerRadius(layoutConfig.isWideSize ? 8 : 4)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, layoutConfig.horizontalPadding)
        .padding(.vertical)
    }

    @ViewBuilder
    private var header: some View {
        let dates = ScheduleUtils.dates(ofWeek: targetWeek, semesterStartDate: semesterStartDate)

        HStack(spacing: layoutConfig.colSpacing) {
            // 左上角月份显示区
            VStack(alignment: .center, spacing: 0) {
                if let firstDate = dates.first {
                    Text(CourseSchedulePresentation.monthFormatter.string(from: firstDate))
                        .font(.system(size: layoutConfig.isWideSize ? 18 : 14, weight: .bold))
                    Text("月")
                        .font(.system(size: layoutConfig.isWideSize ? 14 : 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: layoutConfig.timeColWidth)

            // "周日" 到 "周六"
            ForEach(Array(zip(DayOfWeek.allCases, dates)), id: \.0) { day, date in
                let isToday = ScheduleUtils.isToday(date)
                VStack(spacing: 2) {
                    Text(day.chineseShortString)
                        .font(.system(size: layoutConfig.isWideSize ? 15 : 11))
                        .foregroundColor(isToday ? .accentColor : .secondary)
                        .fontWeight(isToday ? .bold : .medium)

                    ZStack {
                        Circle()
                            .fill(isToday ? Color.accentColor : Color.clear)

                        Text(CourseSchedulePresentation.dayFormatter.string(from: date))
                            .font(.system(size: layoutConfig.isWideSize ? 18 : 14, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white : .primary)
                    }
                    .frame(width: layoutConfig.isWideSize ? 36 : 26, height: layoutConfig.isWideSize ? 36 : 26)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 6)
        .padding(.horizontal, layoutConfig.horizontalPadding)
        .apply { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view
                    .background {
                        Rectangle()
                            .fill(.clear)
                            .glassEffect()
                            .padding(.horizontal, 4)
                    }
                    .padding(.top, 8)
            } else {
                view.background(.ultraThinMaterial)
            }
        }
    }
}
