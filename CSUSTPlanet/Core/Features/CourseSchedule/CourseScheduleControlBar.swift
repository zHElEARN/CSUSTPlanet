//
//  CourseScheduleControlBar.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/6/18.
//

import SwiftUI

struct CourseScheduleControlBar: View {
    @Environment(\.courseScheduleLayoutConfig) private var layoutConfig

    @State private var isRemarkPopoverPresented = false

    let remarks: [String]

    let subtitle: String?
    let realCurrentWeek: Int?

    @Binding var currentWeek: Int
    let weekCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("今日 \(CourseScheduleUtil.dateFormatter.string(from: .now))")
                    .font(layoutConfig.isWideSize ? .title3 : .headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if #unavailable(iOS 26.0) {
                    Text(subtitle ?? "默认学期")
                        .font(layoutConfig.isWideSize ? .subheadline : .caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Picker("选择周数", selection: $currentWeek.withAnimation()) {
                    ForEach(1...weekCount, id: \.self) { week in
                        Text("第 \(week) 周").tag(week)
                    }
                }
                .fixedSize()

                Button(action: {
                    withAnimation {
                        if let realWeek = realCurrentWeek, realWeek > 0 && realWeek <= weekCount {
                            self.currentWeek = realWeek
                        } else {
                            self.currentWeek = 1
                        }
                    }
                }) {
                    Text("本周").fontWeight(.medium)
                }
                .fixedSize()
                .disabled(realCurrentWeek == nil || currentWeek == realCurrentWeek)

                if !remarks.isEmpty {
                    Button(action: { isRemarkPopoverPresented = true }) {
                        Image(systemName: "info.circle")
                    }
                    .popover(isPresented: $isRemarkPopoverPresented) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("课程备注")
                                    .font(.headline)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)

                                Divider()

                                ForEach(remarks.indices, id: \.self) { index in
                                    Text(remarks[index])
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.vertical, 12)

                                    if index < remarks.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        // .frame(minWidth: 240, maxWidth: 300)
                        .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if os(iOS)
        .background(Color(PlatformColor.systemBackground))
        #endif
    }
}

#Preview("CourseScheduleConflictCard") {
    @Previewable @State var currentWeek = CourseSchedulePreviewData.currentWeek

    CourseScheduleControlBar(
        remarks: CourseSchedulePreviewData.remarks,
        subtitle: CourseSchedulePreviewData.subtitle,
        realCurrentWeek: CourseSchedulePreviewData.realCurrentWeek,
        currentWeek: $currentWeek,
        weekCount: CourseSchedulePreviewData.weekCount
    )
}
