//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

#if os(iOS)
import Toasts
#endif

struct FeatureItem: Identifiable {
    let id: TabItem
    let title: String
    let icon: String
    let color: Color
    let destination: () -> AnyView

    init<Content: View>(id: TabItem, title: String, icon: String, color: Color, @ViewBuilder destination: @escaping () -> Content) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.destination = { AnyView(destination()) }
    }
}

struct FeatureSection: Identifiable {
    var id: String { title }
    let title: String
    let items: [FeatureItem]
}

@MainActor
private let featureSections: [FeatureSection] = [
    FeatureSection(
        title: "教务系统",
        items: [
            FeatureItem(id: .courseSchedule, title: "我的课表", icon: "calendar", color: .purple, destination: { CourseScheduleView() }),
            FeatureItem(id: .gradeQuery, title: "成绩查询", icon: "doc.text.magnifyingglass", color: .blue, destination: { GradeQueryView() }),
            FeatureItem(id: .examSchedule, title: "考试安排", icon: "pencil.and.outline", color: .orange, destination: { ExamScheduleView() }),
            FeatureItem(id: .gradeAnalysis, title: "成绩分析", icon: "chart.bar.xaxis", color: .green, destination: { GradeAnalysisView() }),
        ]
    ),
    FeatureSection(
        title: "网络课程中心",
        items: [
            FeatureItem(id: .courses, title: "所有课程", icon: "books.vertical.fill", color: .indigo, destination: { CoursesView() }),
            FeatureItem(id: .urgentCourses, title: "待提交作业", icon: "list.bullet.clipboard", color: .red, destination: { UrgentCoursesView() }),
        ]
    ),
    FeatureSection(
        title: "校园工具",
        items: [
            FeatureItem(id: .electricityQuery, title: "电量查询", icon: "bolt.fill", color: .yellow, destination: { ElectricityQueryView() }),
            FeatureItem(id: .availableClassroom, title: "空教室查询", icon: "building.2.fill", color: .blue, destination: { AvailableClassroomView() }),
            FeatureItem(id: .campusMap, title: "校园地图", icon: "map.fill", color: .mint, destination: { CampusMapView() }),
            FeatureItem(id: .schoolCalendar, title: "校历", icon: "calendar.badge.clock", color: .pink, destination: { SchoolCalendarListView() }),
            FeatureItem(id: .electricityRecharge, title: "电费充值", icon: "creditcard.fill", color: .cyan, destination: { ElectricityRechargeView() }),
            FeatureItem(id: .webVPNConverter, title: "WebVPN", icon: "lock.shield", color: .gray, destination: { WebVPNConverterView() }),
        ]
    ),
    FeatureSection(
        title: "大学物理实验",
        items: [
            FeatureItem(id: .physicsExperimentSchedule, title: "实验安排", icon: "calendar", color: .purple, destination: { PhysicsExperimentScheduleView().environmentObject(PhysicsExperimentManager.shared) }),
            FeatureItem(id: .physicsExperimentGrade, title: "实验成绩", icon: "doc.text", color: .purple, destination: { PhysicsExperimentGradeView().environmentObject(PhysicsExperimentManager.shared) }),
        ]
    ),
    FeatureSection(
        title: "其他考试查询",
        items: [
            FeatureItem(id: .cet, title: "四六级查询", icon: "character.book.closed", color: .indigo, destination: { CETView() }),
            FeatureItem(id: .mandarin, title: "普通话查询", icon: "mic.circle.fill", color: .indigo, destination: { MandarinView() }),
        ]
    ),
]

struct ContentView: View {
    @EnvironmentObject var globalManager: GlobalManager
    @EnvironmentObject var authManager: AuthManager
    #if os(iOS)
    @Environment(\.presentToast) var presentToast
    #endif
    @Environment(\.horizontalSizeClass) var sizeClass

    var preferredColorScheme: ColorScheme? {
        switch globalManager.appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil
        }
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, macOS 15.0, *) {
                TabView(selection: $globalManager.selectedTab) {
                    Tab("概览", systemImage: "rectangle.stack", value: TabItem.overview) {
                        NavigationStack { OverviewView() }
                    }
                    if sizeClass == .compact {
                        Tab("全部功能", systemImage: "square.grid.2x2", value: TabItem.features) {
                            NavigationStack { FeaturesView() }
                        }
                        Tab("我的", systemImage: "person", value: TabItem.profile) {
                            NavigationStack { ProfileView() }
                        }
                    } else {
                        Tab("我的", systemImage: "person", value: TabItem.profile) {
                            NavigationStack { ProfileView() }
                        }
                        ForEach(featureSections) { section in
                            TabSection(section.title) {
                                ForEach(section.items) { item in
                                    Tab(item.title, systemImage: item.icon, value: item.id) {
                                        NavigationStack { item.destination() }
                                    }
                                }
                            }
                        }
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
            } else {
                if sizeClass == .compact {
                    TabView(selection: $globalManager.selectedTab) {
                        NavigationStack { OverviewView() }
                            .tabItem { Label("概览", systemImage: "rectangle.stack") }
                            .tag(TabItem.overview)
                        NavigationStack { FeaturesView() }
                            .tabItem { Label("全部功能", systemImage: "square.grid.2x2") }
                            .tag(TabItem.features)
                        NavigationStack { ProfileView() }
                            .tabItem { Label("我的", systemImage: "person") }
                            .tag(TabItem.profile)
                    }
                } else {
                    NavigationSplitView {
                        List(selection: $globalManager.selectedTab) {
                            Section {
                                ColoredLabel(title: "概览", iconName: "rectangle.stack", color: .blue).tag(TabItem.overview)
                                ColoredLabel(title: "我的", iconName: "person", color: .blue).tag(TabItem.profile)
                            }
                            ForEach(featureSections) { section in
                                Section(section.title) {
                                    ForEach(section.items) { item in
                                        ColoredLabel(title: item.title, iconName: item.icon, color: item.color).tag(item.id)
                                    }
                                }
                            }
                        }
                        .navigationTitle("长理星球")
                    } detail: {
                        NavigationStack {
                            switch globalManager.selectedTab {
                            case .overview:
                                OverviewView()
                            case .profile:
                                ProfileView()
                            case nil:
                                ContentUnavailableView("请选择项目", systemImage: "list.bullet")
                            default:
                                if let item = featureSections.flatMap({ $0.items }).first(where: { $0.id == globalManager.selectedTab }) {
                                    item.destination()
                                } else {
                                    ContentUnavailableView("未找到页面", systemImage: "xmark.circle")
                                }
                            }
                        }
                    }
                }
            }
        }
        .trackRoot("App")

        .apply { view in
            if #available(iOS 26.0, *) {
                view.tabBarMinimizeBehavior(.onScrollDown)
            } else {
                view
            }
        }

        // MARK: 全局Toast状态

        #if os(iOS)
        .onChange(of: authManager.isShowingSSOInfo) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "info.circle.fill").foregroundStyle(.blue), message: authManager.ssoInfo))
            authManager.isShowingSSOInfo = false
        }
        .onChange(of: authManager.isShowingSSOError) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red), message: "统一身份认证登录错误"))
            authManager.isShowingSSOError = false
        }
        .onChange(of: authManager.isShowingEducationInfo) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "info.circle.fill").foregroundStyle(.blue), message: authManager.educationInfo))
            authManager.isShowingEducationInfo = false
        }
        .onChange(of: authManager.isShowingEducationError) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red), message: "教务登录错误"))
            authManager.isShowingEducationError = false
        }
        .onChange(of: authManager.isShowingMoocInfo) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "info.circle.fill").foregroundStyle(.blue), message: authManager.moocInfo))
            authManager.isShowingMoocInfo = false
        }
        .onChange(of: authManager.isShowingMoocError) { _, newValue in
            guard newValue else { return }
            presentToast(ToastValue(icon: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red), message: "网络课程中心登录错误"))
            authManager.isShowingMoocError = false
        }
        #endif

        // MARK: - 主题设置 & 用户协议弹窗

        .preferredColorScheme(preferredColorScheme)
        .sheet(isPresented: globalManager.isUserAgreementShowing) {
            UserAgreementView().interactiveDismissDisabled(true)
        }

        // MARK: - URL处理

        .onOpenURL { url in
            guard url.scheme == "csustplanet", url.host == "widgets" else { return }
            globalManager.selectedTab = TabItem.overview
            switch url.pathComponents.dropFirst().first {
            case "electricity": globalManager.isFromElectricityWidget = true
            case "gradeAnalysis": globalManager.isFromGradeAnalysisWidget = true
            case "courseSchedule": globalManager.isFromCourseScheduleWidget = true
            case "urgentCourses": globalManager.isFromUrgentCoursesWidget = true
            default: break
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalManager.shared)
        .environmentObject(AuthManager.shared)
}
