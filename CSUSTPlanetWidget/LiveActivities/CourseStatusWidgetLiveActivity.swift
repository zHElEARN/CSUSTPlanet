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

/// 课程实时活动的相位
enum CourseStatusPhase: String, Codable, Hashable, Sendable {
    /// 上课前（系统已启动活动，等待上课）
    case upcoming
    /// 上课中
    case inClass
    /// 已下课
    case finished

    /// 灵动岛紧凑视图的相位文案
    var compactTitle: String {
        switch self {
        case .upcoming:
            return "即将上课"
        case .inClass:
            return "上课中"
        case .finished:
            return "已下课"
        }
    }
}

/// 课程实时活动的时间参数
///
/// 该文件同时编译进 App 与 widget target，因此这里的时间参数是两个 target 唯一的一份：
/// App 侧的 `CourseLiveActivityPlanner` 直接引用，widget 侧的旧数据解码兜底也使用同一份。
enum CourseStatusLiveActivityTiming {
    /// 上课前提前启动实时活动的时间
    static let triggerLeadTime: TimeInterval = 20 * 60
    /// 下课后保留实时活动的时间
    static let dismissDelay: TimeInterval = 5 * 60
}

struct CourseStatusWidgetAttributes: ActivityAttributes, Equatable, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        /// App 写入的相位
        ///
        /// 系统只会在 `staleDate`（上课时间）到点时重新渲染视图，因此“课中”相位可以只依赖 `isStale`；
        /// 下课后不会再有第二次相位变化，卡片会停在“距离下课还有 00:00”与满格进度条上，直到 App
        /// 把相位补写为 `.finished`（系统没有按时间结束实时活动的 API）：前台对账会补写，若用户开启了
        /// 「课程实时活动」后台任务，后台对账也能补写。
        var phase: CourseStatusPhase
    }

    var courseName: String
    var teacher: String
    var classroom: String?

    /// 上课时间
    var startDate: Date
    /// 下课时间
    var endDate: Date
    /// 系统启动实时活动并弹出提醒的时间：上课时间 − 课前提前量
    ///
    /// 提前量见 `CourseStatusLiveActivityTiming.triggerLeadTime`（当前为 20 分钟）。
    var triggerDate: Date
    /// App 清理实时活动的时间
    ///
    /// 通常为「下课时间 + 下课后保留时长」，但两节课间隔过短时会提前到「下一节课触发时间 − 安全间隔」，
    /// 且不早于「下课时间 + 最小保留时长」，具体见 `CourseLiveActivityPlanner.dismissalDate(endDate:nextCourseStartDate:)`。
    /// 系统不会按时间结束活动，该时间只作为 App 调用 `end(_:dismissalPolicy:)` 时的移除依据（前台对账，
    /// 或用户开启了「课程实时活动」后台任务时的后台对账）。
    var dismissDate: Date
}

extension CourseStatusWidgetAttributes.ContentState {
    /// 为兼容旧版本活动数据（旧 `ContentState` 只有 `now`）保留的自定义解码，勿改回合成解码
    ///
    /// 旧数据的 `now` 会被忽略，缺失的 `phase` 落到 `.upcoming`；实际展示相位随后由 `isStale`
    /// （系统在 `staleDate` 到点时置位）与 App 的相位补正决定。编码仍使用合成实现。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.phase = try container.decodeIfPresent(CourseStatusPhase.self, forKey: .phase) ?? .upcoming
    }
}

extension CourseStatusWidgetAttributes {
    /// 为兼容旧版本活动数据（旧 attributes 没有 `triggerDate` / `dismissDate`）保留的自定义解码，勿改回合成解码
    ///
    /// 两个时间字段缺失时按「上课时间 − 课前提前量」「下课时间 + 下课后保留时长」兜底：兜底值与
    /// `CourseActivityPlan` 的排期一致，因此旧活动仍能通过 `CourseActivityPlan.matches(_:)` 的比对，
    /// 由 App 后续对账时按真实排期补正相位与清理时间。编码仍使用合成实现。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.courseName = try container.decode(String.self, forKey: .courseName)
        self.teacher = try container.decode(String.self, forKey: .teacher)
        self.classroom = try container.decodeIfPresent(String.self, forKey: .classroom)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.triggerDate =
            try container.decodeIfPresent(Date.self, forKey: .triggerDate)
            ?? startDate.addingTimeInterval(-CourseStatusLiveActivityTiming.triggerLeadTime)
        self.dismissDate =
            try container.decodeIfPresent(Date.self, forKey: .dismissDate)
            ?? endDate.addingTimeInterval(CourseStatusLiveActivityTiming.dismissDelay)
    }
}

extension CourseStatusWidgetAttributes {
    /// 上课前倒计时区间（上课前提前量 ~ 上课时间）
    ///
    /// 脏数据（上课时间早于触发时间）会让 `ClosedRange` 构造崩溃，因此对区间做夹取作为最后一道防线。
    var upcomingInterval: ClosedRange<Date> {
        triggerDate...max(triggerDate, startDate)
    }

    /// 上课中倒计时与进度区间（上课时间 ~ 下课时间）
    ///
    /// 同上，脏数据（下课时间早于上课时间）时夹取为「上课时间 ~ 上课时间」。
    var inClassInterval: ClosedRange<Date> {
        startDate...max(startDate, endDate)
    }
}

extension ActivityViewContext where Attributes == CourseStatusWidgetAttributes {
    /// 结合 App 写入的相位与系统 stale 标记，得到当前需要展示的相位
    ///
    /// 系统在活动进入 stale（上课时间）时会重新渲染视图，因此课前与课中的切换不依赖 App；
    /// 下课后系统不会再次渲染也不会结束活动，只能由 App 把相位补写为 `finished` 并按
    /// `dismissDate` 结束，否则卡片会一直停留在“距离下课还有 00:00”。
    var courseStatusPhase: CourseStatusPhase {
        if state.phase == .finished {
            return .finished
        }
        if isStale || state.phase == .inClass {
            return .inClass
        }
        return .upcoming
    }
}

struct CourseStatusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CourseStatusWidgetAttributes.self) { context in
            CourseStatusLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.teacher)
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
                    CourseStatusDynamicIslandExpandedView(context: context)
                }
            } compactLeading: {
                Text(context.courseStatusPhase.compactTitle)
                    .font(.caption2)
            } compactTrailing: {
                CourseStatusCompactTrailingView(context: context)
            } minimal: {
                Image("MinimalLogo")
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

/// 灵动岛展开后的课程状态
struct CourseStatusDynamicIslandExpandedView: View {
    let context: ActivityViewContext<CourseStatusWidgetAttributes>

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(context.attributes.courseName)
                .font(.headline)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            switch context.courseStatusPhase {
            case .upcoming:
                Text("距离上课还有")
                    .font(.callout)
                Text(timerInterval: context.attributes.upcomingInterval, countsDown: true)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.cyan)
            case .inClass:
                Text("距离下课还有")
                    .font(.caption2)
                Text(timerInterval: context.attributes.inClassInterval, countsDown: true)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.cyan)
                ProgressView(timerInterval: context.attributes.inClassInterval, countsDown: false)
                    .progressViewStyle(.linear)
                    .tint(.cyan)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            case .finished:
                Text("已下课")
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.green)
            }
        }
    }
}

/// 灵动岛紧凑视图的计时器
struct CourseStatusCompactTrailingView: View {
    let context: ActivityViewContext<CourseStatusWidgetAttributes>

    var body: some View {
        switch context.courseStatusPhase {
        case .upcoming:
            timer("00:00") {
                Text(timerInterval: context.attributes.upcomingInterval, countsDown: true)
            }
        case .inClass:
            timer(inClassPlaceholder) {
                Text(timerInterval: context.attributes.inClassInterval, countsDown: true)
            }
        case .finished:
            Text("已下课")
                .font(.caption2)
        }
    }

    /// 上课时长达到 1 小时时预留更宽的位置，避免灵动岛宽度跳动
    private var inClassPlaceholder: String {
        context.attributes.endDate.timeIntervalSince(context.attributes.startDate) >= 3600 ? "00:00:00" : "00:00"
    }

    private func timer<Content: View>(_ placeholder: String, @ViewBuilder content: () -> Content) -> some View {
        Text(placeholder)
            .font(.caption2)
            .hidden()
            .overlay(alignment: .trailing) {
                content()
                    .font(.caption2)
                    .monospacedDigit()
            }
    }
}

struct CourseStatusLockScreenView: View {
    let context: ActivityViewContext<CourseStatusWidgetAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(context.attributes.courseName)
                    .font(.title2).bold()

                Spacer()

                VStack(alignment: .trailing) {
                    Text(context.attributes.teacher)
                        .font(.caption)
                    Text(context.attributes.classroom ?? "无教室")
                        .font(.caption)
                }
            }

            Divider()

            switch context.courseStatusPhase {
            case .upcoming:
                VStack(alignment: .leading) {
                    Text("距离上课还有")
                        .font(.caption)
                    Text(timerInterval: context.attributes.upcomingInterval, countsDown: true)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.cyan)
                }
            case .inClass:
                VStack(alignment: .leading) {
                    Text("距离下课还有")
                        .font(.caption)
                    Text(timerInterval: context.attributes.inClassInterval, countsDown: true)
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(.cyan)
                }
                ProgressView(timerInterval: context.attributes.inClassInterval, countsDown: false)
                    .progressViewStyle(.linear)
                    .tint(.cyan)
            case .finished:
                Label("已下课", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.5))
    }
}

extension CourseStatusWidgetAttributes {
    static var preview: CourseStatusWidgetAttributes {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let startDate = dateFormatter.date(from: "2025-10-20 13:50")!
        let endDate = dateFormatter.date(from: "2025-10-20 15:40")!
        return .init(
            courseName: "程序设计、算法与数据结构（三）",
            teacher: "陈曦(小)副教授",
            classroom: "金12-106",
            startDate: startDate,
            endDate: endDate,
            triggerDate: startDate.addingTimeInterval(-CourseStatusLiveActivityTiming.triggerLeadTime),
            dismissDate: endDate.addingTimeInterval(CourseStatusLiveActivityTiming.dismissDelay)
        )
    }
}

#Preview("Notification", as: .content, using: CourseStatusWidgetAttributes.preview) {
    CourseStatusWidgetLiveActivity()
} contentStates: {
    CourseStatusWidgetAttributes.ContentState(phase: .upcoming)
}

#endif
