//
//  PhysicsExperimentScheduleContent.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/23.
//

import CSUSTKit
import SwiftUI

struct PhysicsExperimentScheduleContent: View {
    let data: Cached<[PhysicsExperimentHelper.Course]>?

    let isLoadingSchedules: Bool

    @Binding var isLoginPresented: Bool
    @Binding var errorToast: ToastState
    @Binding var warningToast: ToastState

    let onRefreshSchedules: () async -> Void

    private var courses: [PhysicsExperimentHelper.Course] {
        data?.value ?? []
    }

    var body: some View {
        Group {
            if courses.isEmpty {
                ContentUnavailableView(
                    "暂无实验安排",
                    systemImage: "flask",
                    description: Text("没有找到任何大物实验安排信息")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                CustomScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(courses, id: \.id) { course in
                            ScheduleCardView(course: course)
                        }
                    }
                    .padding()
                }
            }
        }
        .errorToast($errorToast)
        .warningToast($warningToast)
        .sheet(isPresented: $isLoginPresented) {
            PhysicsExperimentLoginView()
        }
        .safeRefreshable { await onRefreshSchedules() }
        .navigationTitle("大物实验安排")
        .navigationSubtitleCompat("共\(courses.count)个实验")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { isLoginPresented = true }) {
                    Text("登录")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(asyncAction: onRefreshSchedules) {
                    if isLoadingSchedules {
                        ProgressView().smallControlSizeOnMac()
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoadingSchedules)
            }
        }
    }
}

struct ScheduleCardView: View {
    let course: PhysicsExperimentHelper.Course
    let now: Date = .now

    private var isFinished: Bool {
        return now > course.endTime
    }

    private var daysUntil: Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let courseDay = calendar.startOfDay(for: course.startTime)
        let components = calendar.dateComponents([.day], from: startOfDay, to: courseDay)
        return components.day ?? 0
    }

    var body: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .top, spacing: 12) {
                    Text(course.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isFinished ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        if isFinished {
                            Text("已结束")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.15), in: Capsule())
                        } else {
                            if daysUntil == 0 {
                                Text("今天")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red, in: Capsule())
                            } else if daysUntil == 1 {
                                Text("明天")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange, in: Capsule())
                            } else {
                                Text("还有 \(daysUntil) 天")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                        }

                        Text("批次 \(course.batch)")
                            .font(.caption.bold())
                            .foregroundStyle(isFinished ? .gray : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isFinished ? Color.gray.opacity(0.15) : Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 12)

                Divider()
                    .padding(.bottom, 12)

                // Info Rows
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(icon: "calendar", color: .blue, text: formatTime(course: course), finished: isFinished)

                    detailRow(icon: "mappin.and.ellipse", color: .red, text: course.location, finished: isFinished)

                    HStack(spacing: 0) {
                        detailRow(icon: "person.fill", color: .purple, text: course.teacher, finished: isFinished)
                        Spacer()
                        detailRow(icon: "clock", color: .orange, text: "\(course.classHours) 课时", finished: isFinished)
                    }
                }
            }
        }
        .opacity(isFinished ? 0.6 : 1.0)
        .saturation(isFinished ? 0.0 : 1.0)
    }

    // 辅助视图：详情行
    @ViewBuilder
    private func detailRow(icon: String, color: Color, text: String, finished: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(finished ? .gray : color)
                .frame(width: 16)

            Text(text)
                .font(.subheadline)
                .foregroundColor(finished ? .secondary : .primary)
                .lineLimit(1)
        }
    }

    private func formatTime(course: PhysicsExperimentHelper.Course) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: course.startTime)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let startStr = timeFormatter.string(from: course.startTime)
        let endStr = timeFormatter.string(from: course.endTime)

        return "\(dateStr) 周\(course.dayOfWeek.stringValue) \(startStr)-\(endStr)"
    }
}

#Preview("PhysicsExperimentScheduleContent") {
    @Previewable @State var isLoginPresented = false
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var warningToast = ToastState.warningTitle

    NavigationStack {
        PhysicsExperimentScheduleContent(
            data: Cached(cachedAt: .now, value: PhysicsExperimentSchedulePreviewData.courses),
            isLoadingSchedules: false,
            isLoginPresented: $isLoginPresented,
            errorToast: $errorToast,
            warningToast: $warningToast,
            onRefreshSchedules: {}
        )
    }
}

#Preview("PhysicsExperimentScheduleContent Empty") {
    @Previewable @State var isLoginPresented = false
    @Previewable @State var errorToast = ToastState.errorTitle
    @Previewable @State var warningToast = ToastState.warningTitle

    NavigationStack {
        PhysicsExperimentScheduleContent(
            data: Cached(cachedAt: .now, value: []),
            isLoadingSchedules: false,
            isLoginPresented: $isLoginPresented,
            errorToast: $errorToast,
            warningToast: $warningToast,
            onRefreshSchedules: {}
        )
    }
}

// MARK: - Preview Data

private enum PhysicsExperimentSchedulePreviewData {
    static let courses: [PhysicsExperimentHelper.Course] = [
        makeCourse(1, "用示波器观测周期性电信号", "周一第3批", "张三", "工科楼 A301", -7, 14, 17, .monday),
        makeCourse(2, "分光计的调节与使用", "周三第1批", "李四", "工科楼 B205", 0, 8, 11, .wednesday),
        makeCourse(3, "光电效应测普朗克常数", "周五第2批", "王五", "工科楼 A104", 3, 14, 17, .friday),
    ]

    private static func makeCourse(
        _ id: Int,
        _ name: String,
        _ batch: String,
        _ teacher: String,
        _ location: String,
        _ dayOffset: Int,
        _ startHour: Int,
        _ endHour: Int,
        _ dayOfWeek: EduHelper.DayOfWeek
    ) -> PhysicsExperimentHelper.Course {
        PhysicsExperimentHelper.Course(
            id: id,
            name: name,
            batch: batch,
            teacher: teacher,
            location: location,
            startTime: makeDate(dayOffset: dayOffset, hour: startHour),
            endTime: makeDate(dayOffset: dayOffset, hour: endHour),
            classHours: endHour - startHour,
            week: 1,
            dayOfWeek: dayOfWeek
        )
    }

    private static func makeDate(dayOffset: Int, hour: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: dayOffset, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}
