//
//  CourseScheduleDetailView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct CourseScheduleDetailView: View {
    let course: EduHelper.Course
    let session: EduHelper.ScheduleSession
    let isShowingToolbar: Bool
    @Binding var isPresented: Bool
    @StateObject private var mapViewModel = CampusMapViewModel()


    private var otherSessions: [EduHelper.ScheduleSession] {
        course.sessions.filter { $0 != session }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 课程基本信息
                Section {
                    VStack(spacing: 8) {
                        Text(course.courseName)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        HStack(spacing: 12) {
                            if let teacher = course.teacher {
                                Label(teacher, systemImage: "person.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let groupName = course.groupName {
                                Text(groupName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // MARK: - 本次安排
                Section("本次安排") {
                    FormRow(label: "课程周次", value: formatWeeks(session.weeks))
                    FormRow(label: "上课时间", value: "\(session.dayOfWeek.chineseLongString) · 第\(session.startSection)-\(session.endSection)节")
                    if let classroom = session.classroom {
                        LabeledContent("上课教室") {
                            ClassroomNavigationView(classroom: classroom, session: session, mapViewModel: mapViewModel)
                        }
                        .contentShape(.rect)
                    } else {
                        FormRow(label: "上课教室", value: "未安排教室")
                    }
                }

                // MARK: - 其他安排
                if !otherSessions.isEmpty {
                    Section("其他安排") {
                        ForEach(otherSessions, id: \.self) { otherSession in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(otherSession.dayOfWeek.chineseLongString)
                                        .fontWeight(.medium)
                                    Text("第\(otherSession.startSection)-\(otherSession.endSection)节")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    
                                    if let classroom = otherSession.classroom {
                                        ClassroomNavigationView(classroom: classroom, session: otherSession, mapViewModel: mapViewModel, isSubheadline: true)
                                    } else {
                                        Text("未安排教室")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Text(formatWeeks(otherSession.weeks))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("课程详情")
            .task {
                await mapViewModel.loadBuildings()
            }
            .inlineToolbarTitle()
            .apply { view in
                if isShowingToolbar {
                    view.toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") {
                                isPresented = false
                            }
                        }
                    }
                } else {
                    view
                }
            }
        }
    }
}

// MARK: - Helpers
extension CourseScheduleDetailView {
    private func formatWeeks(_ weeks: [Int]) -> String {
        guard !weeks.isEmpty else { return "" }

        var result = [String]()
        var start = weeks[0]
        var prev = weeks[0]

        for week in weeks.dropFirst() {
            if week == prev + 1 {
                prev = week
            } else {
                if start == prev {
                    result.append("第\(start)周")
                } else {
                    result.append("第\(start)-\(prev)周")
                }
                start = week
                prev = week
            }
        }

        if start == prev {
            result.append("第\(start)周")
        } else {
            result.append("第\(start)-\(prev)周")
        }

        return result.joined(separator: ", ")
    }
}

// MARK: - Map Feature Matching
extension EduHelper.ScheduleSession {
    /// 在给定的建筑列表中找到匹配的建筑 Feature (用于在地图上定位)
    func matchedFeature(in buildings: [PlanetConfigService.Feature]) -> PlanetConfigService.Feature? {
        guard let fullName = buildingFullName else { return nil }
        return buildings.first { feature in
            if let campus = campusName {
                return feature.properties.name == fullName && feature.properties.campus == campus
            }
            return feature.properties.name == fullName
        }
    }
}

// MARK: - Classroom Navigation View
private struct ClassroomNavigationView: View {
    let classroom: String
    let session: EduHelper.ScheduleSession
    @ObservedObject var mapViewModel: CampusMapViewModel
    var isSubheadline: Bool = false
    
    var body: some View {
        if let feature = session.matchedFeature(in: mapViewModel.allBuildings) {
            Button(action: {
                mapViewModel.openNavigation(for: feature)
            }) {
                HStack(spacing: isSubheadline ? 2 : 4) {
                    Text(classroom)
                        .font(isSubheadline ? .subheadline : .body)
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(isSubheadline ? .caption2 : .body)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        } else {
            let isLoading = mapViewModel.isLoading && mapViewModel.allBuildings.isEmpty
            let reason = isLoading ? "正在获取地图数据..." : (mapViewModel.allBuildings.isEmpty ? "网络未连接或无缓存" : "地图暂无该建筑坐标")
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: isSubheadline ? 2 : 4) {
                    Text(classroom)
                        .font(isSubheadline ? .subheadline : .body)
                    Image(systemName: "arrow.up.right")
                        .font(isSubheadline ? .caption2 : .body)
                }
                .foregroundStyle(.secondary)
                .onAppear {
                    if !isLoading {
                        print("[Debug] 课程地图导航不可用 - 原因: \(reason), 教室: \(classroom)")
                    }
                }
                .onChange(of: isLoading) { _ in
                    if !mapViewModel.isLoading && session.matchedFeature(in: mapViewModel.allBuildings) == nil {
                        let finalReason = mapViewModel.allBuildings.isEmpty ? "网络未连接或无缓存" : "地图暂无该建筑坐标"
                        print("[Debug] 课程地图导航不可用 - 原因: \(finalReason), 教室: \(classroom)")
                    }
                }
                
                Text(reason)
                    .font(isSubheadline ? .system(size: 9) : .caption2)
                    .foregroundStyle(isLoading ? Color.secondary : Color.red.opacity(0.8))
            }
        }
    }
}

