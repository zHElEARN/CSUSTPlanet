//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI
import Toasts

struct ContentView: View {
    @EnvironmentObject var globalManager: GlobalManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentToast) var presentToast
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
                        NavigationStack {
                            OverviewView()
                        }
                    }
                    if sizeClass == .compact {
                        Tab("全部功能", systemImage: "square.grid.2x2", value: TabItem.features) {
                            NavigationStack {
                                FeaturesView()
                            }
                        }
                    } else {
                        TabSection("教务系统") {
                            Tab("我的课表", systemImage: "calendar", value: TabItem.courseSchedule) {
                                NavigationStack {
                                    CourseScheduleView()
                                }
                            }
                            Tab("成绩查询", systemImage: "doc.text.magnifyingglass", value: TabItem.gradeQuery) {
                                NavigationStack {
                                    GradeQueryView()
                                }
                            }
                            Tab("考试安排", systemImage: "pencil.and.outline", value: TabItem.examSchedule) {
                                NavigationStack {
                                    ExamScheduleView()
                                }
                            }
                            Tab("成绩分析", systemImage: "chart.bar.xaxis", value: TabItem.gradeAnalysis) {
                                NavigationStack {
                                    GradeAnalysisView()
                                }
                            }
                        }

                        TabSection("网络课程中心") {
                            Tab("所有课程", systemImage: "books.vertical.fill", value: TabItem.courses) {
                                NavigationStack {
                                    CoursesView()
                                }
                            }
                            Tab("待提交作业", systemImage: "list.bullet.clipboard", value: TabItem.urgentCourses) {
                                NavigationStack {
                                    UrgentCoursesView()
                                }
                            }
                        }

                        TabSection("校园工具") {
                            Tab("电量查询", systemImage: "bolt.fill", value: TabItem.electricityQuery) {
                                NavigationStack {
                                    ElectricityQueryView()
                                }
                            }
                            Tab("空教室查询", systemImage: "building.2.fill", value: TabItem.availableClassroom) {
                                NavigationStack {
                                    AvailableClassroomView()
                                }
                            }
                            Tab("校园地图", systemImage: "map.fill", value: TabItem.campusMap) {
                                NavigationStack {
                                    CampusMapView()
                                }
                            }
                            Tab("校历", systemImage: "calendar.badge.clock", value: TabItem.schoolCalendar) {
                                NavigationStack {
                                    SchoolCalendarListView()
                                }
                            }
                            Tab("电费充值", systemImage: "creditcard.fill", value: TabItem.electricityRecharge) {
                                NavigationStack {
                                    ElectricityRechargeView()
                                }
                            }
                            Tab("WebVPN", systemImage: "lock.shield", value: TabItem.webVPNConverter) {
                                NavigationStack {
                                    WebVPNConverterView()
                                }
                            }
                        }

                        TabSection("大学物理实验") {
                            Tab("实验安排", systemImage: "calendar", value: TabItem.physicsExperimentSchedule) {
                                NavigationStack {
                                    PhysicsExperimentScheduleView()
                                        .environmentObject(PhysicsExperimentManager.shared)
                                }
                            }
                            Tab("实验成绩", systemImage: "doc.text", value: TabItem.physicsExperimentGrade) {
                                NavigationStack {
                                    PhysicsExperimentGradeView()
                                        .environmentObject(PhysicsExperimentManager.shared)
                                }
                            }
                        }

                        TabSection("其他考试查询") {
                            Tab("四六级查询", systemImage: "character.book.closed", value: TabItem.cet) {
                                NavigationStack {
                                    CETView()
                                }
                            }
                            Tab("普通话查询", systemImage: "mic.circle.fill", value: TabItem.mandarin) {
                                NavigationStack {
                                    MandarinView()
                                }
                            }
                        }
                    }
                    Tab("我的", systemImage: "person", value: TabItem.profile) {
                        NavigationStack {
                            ProfileView()
                        }
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
            } else {
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
