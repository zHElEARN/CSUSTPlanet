//
//  CourseStatusWidgetLiveActivity.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/15.
//

#if os(iOS)

import ActivityKit
import CSUSTKit
import SwiftUI
import WidgetKit

struct CourseStatusWidgetAttributes: ActivityAttributes, Equatable {
    public struct ContentState: Codable, Hashable {
        var now: Date
    }

    var courseName: String
    var teacher: String?
    var classroom: String?

    var startDate: Date
    var endDate: Date
}

struct CourseStatusWidgetLiveActivity: Widget {
    let dateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CourseStatusWidgetAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(context.attributes.courseName)
                            .font(.title2)
                            .bold()
                            .allowsTightening(true)
                            .minimumScaleFactor(0.7)

                        HStack {
                            Text(context.attributes.classroom ?? "无教室")
                                .font(.caption)
                            Text(context.attributes.teacher ?? "无教师")
                                .font(.caption)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(dateFormatter.string(from: context.attributes.startDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxHeight: .infinity)
                        Text(dateFormatter.string(from: context.attributes.endDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxHeight: .infinity)
                    }
                }
                Divider()
                if context.state.now < context.attributes.startDate {
                    VStack(alignment: .leading) {
                        Text("距离上课还有")
                            .font(.caption)
                        Text(timerInterval: context.state.now...context.attributes.startDate, showsHours: false)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.yellow)
                    }
                } else if context.state.now <= context.attributes.endDate {
                    VStack(alignment: .leading) {
                        Text("距离下课还有")
                            .font(.caption)
                        Text(timerInterval: context.attributes.startDate...context.attributes.endDate, showsHours: false)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.cyan)
                    }
                    ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false, label: {}, currentValueLabel: {})
                        .progressViewStyle(.linear)
                        .tint(.cyan)
                } else {
                    Text("已下课")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.5))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.teacher ?? "无教师")
                        .font(.caption)
                        .padding(.top, 4)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.classroom ?? "无教室")
                        .font(.caption)
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .center, spacing: 0) {
                        Text(context.attributes.courseName)
                            .font(.title3)
                            .bold()
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("\(dateFormatter.string(from: context.attributes.startDate)) - \(dateFormatter.string(from: context.attributes.endDate))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 6)

                        if context.state.now < context.attributes.startDate {
                            Text("距离上课还有")
                                .font(.caption)
                            Text(timerInterval: context.state.now...context.attributes.startDate, showsHours: false)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.yellow)
                        } else if context.state.now >= context.attributes.startDate && context.state.now <= context.attributes.endDate {
                            Text("距离下课还有")
                                .font(.caption)
                            Text(timerInterval: context.attributes.startDate...context.attributes.endDate, showsHours: false)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.cyan)
                            ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false, label: {}, currentValueLabel: {})
                                .progressViewStyle(.linear)
                                .tint(.cyan)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                        } else {
                            Text("已下课")
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.green)
                        }
                    }
                }
            } compactLeading: {
                if context.state.now < context.attributes.startDate {
                    Text("即将上课")
                        .font(.caption2)
                } else if context.state.now >= context.attributes.startDate && context.state.now <= context.attributes.endDate {
                    Text("上课中")
                        .font(.caption2)
                } else {
                    Text("已下课")
                        .font(.caption2)
                }
            } compactTrailing: {
                if context.state.now < context.attributes.startDate {
                    Text("00:00")
                        .font(.caption2)
                        .hidden()
                        .overlay(alignment: .trailing) {
                            Text(timerInterval: context.state.now...context.attributes.startDate, showsHours: false)
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                } else if context.state.now >= context.attributes.startDate && context.state.now <= context.attributes.endDate {
                    Text("00:00")
                        .font(.caption2)
                        .hidden()
                        .overlay(alignment: .trailing) {
                            Text(timerInterval: context.attributes.startDate...context.attributes.endDate, showsHours: false)
                                .font(.caption2)
                                .foregroundStyle(.cyan)
                        }
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                        .imageScale(.large)
                }
            } minimal: {
                if context.state.now < context.attributes.startDate {
                    ProgressView(timerInterval: context.state.now...context.attributes.startDate, countsDown: false, label: {}) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tint)
                    }
                    .progressViewStyle(.circular)
                    .tint(.yellow)
                } else if context.state.now >= context.attributes.startDate && context.state.now <= context.attributes.endDate {
                    ProgressView(timerInterval: context.attributes.startDate...context.attributes.endDate, countsDown: false, label: {}) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tint)
                    }
                    .progressViewStyle(.circular)
                    .tint(.cyan)
                } else {
                    Image("MinimalLogo")
                        .resizable()
                        .scaledToFit()
                }
            }
        }
    }
}

extension CourseStatusWidgetAttributes {
    static var preview: CourseStatusWidgetAttributes {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return .init(
            courseName: "程序设计、算法与数据结构（三）",
            teacher: "陈曦(小)副教授",
            classroom: "金12-106",
            startDate: dateFormatter.date(from: "2025-10-20 14:00")!,
            endDate: dateFormatter.date(from: "2025-10-20 15:40")!
        )
    }

    static var beforeSchedule: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
        return dateFormatter.date(from: "2025-10-20 13:55")!
    }

    static var inSchedule: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
        return dateFormatter.date(from: "2025-10-20 14:55")!
    }

    static var afterSchedule: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm"
        return dateFormatter.date(from: "2025-10-20 15:55")!
    }
}

#Preview("Lock Screen", as: .content, using: CourseStatusWidgetAttributes.preview) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.beforeSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.inSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.afterSchedule)
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: CourseStatusWidgetAttributes.preview) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.beforeSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.inSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.afterSchedule)
}

#Preview("Compact", as: .dynamicIsland(.compact), using: CourseStatusWidgetAttributes.preview) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.beforeSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.inSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.afterSchedule)
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: CourseStatusWidgetAttributes.preview) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.beforeSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.inSchedule)
    CourseStatusWidgetAttributes.ContentState(now: CourseStatusWidgetAttributes.afterSchedule)
}

#endif
