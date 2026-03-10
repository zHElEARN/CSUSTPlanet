//
//  UrgentCoursesEntryView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zhe_Learn on 2025/10/13.
//

import Foundation
import SwiftUI
import WidgetKit

struct UrgentCoursesEntryView: View {
    var entry: UrgentCoursesProvider.Entry

    // MARK: - Body

    var body: some View {
        Group {
            if let data = entry.data, let lastUpdated = entry.lastUpdated {
                contentView(data: data, lastUpdated: lastUpdated)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack(alignment: .topTrailing) {
                    emptyView.frame(maxWidth: .infinity, maxHeight: .infinity)
                    refreshButtonView
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .widgetURL(URL(string: "csustplanet://widgets/urgentCourses"))
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Content View

    @ViewBuilder
    func contentView(data: UrgentCoursesData, lastUpdated: Date) -> some View {
        VStack(spacing: 0) {
            headerView(data: data)
            Divider().padding(.vertical, 4)
            coursesView(data: data).frame(maxWidth: .infinity, maxHeight: .infinity)
            lastUpdatedDateView(lastUpdated: lastUpdated)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    func coursesView(data: UrgentCoursesData) -> some View {
        if data.courses.isEmpty {
            Text("无待提交作业")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        } else {
            GeometryReader { proxy in
                let count = 5
                let courses = data.courses.prefix(count - 1)
                let spacing: CGFloat = 4
                let height = (proxy.size.height - spacing * CGFloat(count - 1)) / CGFloat(count)

                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(courses, id: \.id) { course in
                        Text(course.name)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .frame(height: height)
                    }

                    if data.courses.count > 4 {
                        Text("...")
                            .font(.system(size: 12, weight: .bold))
                            .frame(height: height)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    func headerView(data: UrgentCoursesData) -> some View {
        HStack(alignment: .center, spacing: 4) {
            Text("待提交作业")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
            Text("\(data.courses.count)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.red)
            Spacer()
            refreshButtonView
        }
    }

    // MARK: - Empty View

    var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))
            VStack(spacing: 4) {
                Text("暂无课程数据")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("请点击右上角刷新按钮尝试刷新课程数据")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Refresh Button View

    var refreshButtonView: some View {
        Button(intent: RefreshUrgentCoursesTimelineIntent()) {
            Image(systemName: "arrow.clockwise.circle")
        }
        .foregroundStyle(.blue)
        .buttonStyle(.plain)
    }

    // MARK: - Last Updated Date View

    @ViewBuilder
    func lastUpdatedDateView(lastUpdated: Date) -> some View {
        Text("更新于：")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            + Text(lastUpdated, style: .relative)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
            + Text("前")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
    }
}
