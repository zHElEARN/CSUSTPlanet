//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AlertToast
import SwiftUI

struct FeatureItem: Identifiable {
    let id: TabItem
    let title: String
    let icon: String
    let destination: () -> AnyView

    init<Content: View>(id: TabItem, title: String, icon: String, @ViewBuilder destination: @escaping () -> Content) {
        self.id = id
        self.title = title
        self.icon = icon
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
            FeatureItem(id: .courseSchedule, title: "我的课表", icon: "calendar", destination: { CourseScheduleView() }),
            FeatureItem(id: .gradeQuery, title: "成绩查询", icon: "doc.text.magnifyingglass", destination: { GradeQueryView() }),
            FeatureItem(id: .examSchedule, title: "考试安排", icon: "pencil.and.outline", destination: { ExamScheduleView() }),
            FeatureItem(id: .gradeAnalysis, title: "成绩分析", icon: "chart.bar.xaxis", destination: { GradeAnalysisView() }),
        ]
    ),
    FeatureSection(
        title: "网络课程中心",
        items: [
            FeatureItem(id: .courses, title: "所有课程", icon: "books.vertical.fill", destination: { CoursesView() }),
            FeatureItem(id: .urgentCourses, title: "待提交作业", icon: "list.bullet.clipboard", destination: { TodoAssignmentsView() }),
        ]
    ),
    FeatureSection(
        title: "校园工具",
        items: [
            FeatureItem(id: .electricityQuery, title: "电量查询", icon: "bolt.fill", destination: { DormListView() }),
            FeatureItem(id: .availableClassroom, title: "空教室查询", icon: "building.2.fill", destination: { AvailableClassroomView() }),
            FeatureItem(id: .campusMap, title: "校园地图", icon: "map.fill", destination: { CampusMapView() }),
            FeatureItem(id: .schoolCalendar, title: "校历", icon: "calendar.badge.clock", destination: { SchoolCalendarListView() }),
            FeatureItem(id: .electricityRecharge, title: "电费充值", icon: "creditcard.fill", destination: { ElectricityRechargeView() }),
            FeatureItem(id: .webVPNConverter, title: "WebVPN", icon: "lock.shield", destination: { WebVPNConverterView() }),
        ]
    ),
    FeatureSection(
        title: "大学物理实验",
        items: [
            FeatureItem(id: .physicsExperimentSchedule, title: "实验安排", icon: "calendar", destination: { PhysicsExperimentScheduleView().environmentObject(PhysicsExperimentManager.shared) }),
            FeatureItem(id: .physicsExperimentGrade, title: "实验成绩", icon: "doc.text", destination: { PhysicsExperimentGradeView().environmentObject(PhysicsExperimentManager.shared) }),
        ]
    ),
    FeatureSection(
        title: "其他考试查询",
        items: [
            FeatureItem(id: .cet, title: "四六级查询", icon: "character.book.closed", destination: { CETView() }),
            FeatureItem(id: .mandarin, title: "普通话查询", icon: "mic.circle.fill", destination: { MandarinView() }),
        ]
    ),
]

struct ContentView: View {
    @Bindable var globalManager = GlobalManager.shared
    @Bindable var authManager = AuthManager.shared

    @Environment(\.horizontalSizeClass) var sizeClass

    @State var isDatabaseReady = false

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
            if isDatabaseReady {
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
                                    Label("概览", systemImage: "rectangle.stack").tag(TabItem.overview)
                                    Label("我的", systemImage: "person").tag(TabItem.profile)
                                }
                                ForEach(featureSections) { section in
                                    Section(section.title) {
                                        ForEach(section.items) { item in
                                            Label(item.title, systemImage: item.icon).tag(item.id)
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
            } else {
                ProgressView()
            }
        }
        .trackRoot("App")

        .task {
            // await SharedModelUtil.migrateDatabase()
            withAnimation { isDatabaseReady = true }
        }

        #if os(iOS)
        .apply { view in
            if #available(iOS 26.0, *) {
                view.tabBarMinimizeBehavior(.onScrollDown)
            } else {
                view
            }
        }
        #endif

        // MARK: 全局Toast状态

        .toast(isPresenting: $authManager.isShowingSSOInfo) {
            AlertToast(displayMode: .hud, type: .systemImage("info.circle.fill", .blue), title: authManager.ssoInfo)
        }
        .toast(isPresenting: $authManager.isShowingSSOError) {
            AlertToast(displayMode: .hud, type: .error(.red), title: "统一身份认证登录错误")
        }
        .toast(isPresenting: $authManager.isShowingEducationInfo) {
            AlertToast(displayMode: .hud, type: .systemImage("info.circle.fill", .blue), title: authManager.educationInfo)
        }
        .toast(isPresenting: $authManager.isShowingEducationError) {
            AlertToast(displayMode: .hud, type: .error(.red), title: "教务登录错误")
        }
        .toast(isPresenting: $authManager.isShowingMoocInfo) {
            AlertToast(displayMode: .hud, type: .systemImage("info.circle.fill", .blue), title: authManager.moocInfo)
        }
        .toast(isPresenting: $authManager.isShowingMoocError) {
            AlertToast(displayMode: .hud, type: .error(.red), title: "网络课程中心登录错误")
        }

        // MARK: - 数据库Fatal提示

        // .alert("本地数据异常", isPresented: $globalManager.showWipeRecoveryAlert) {
        //     Button("我知道了", role: .cancel) {}
        // } message: {
        //     Text("检测到本地缓存数据出现异常，为了保证应用正常运行，我们已重置了本地环境。如果您之前开启了 iCloud 同步，您的数据稍后将从云端自动恢复。")
        // }
        // .alert("存储空间不可用", isPresented: $globalManager.showFatalErrorAlert) {
        //     Button("我知道了", role: .cancel) {}
        // } message: {
        //     Text("应用无法访问设备的本地存储空间，当前正以“临时模式”运行。您可以继续浏览信息，但任何关于宿舍电量新的更改或记录在退出应用后都将丢失。建议您检查设备的剩余存储空间，或尝试重启设备。")
        // }

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
