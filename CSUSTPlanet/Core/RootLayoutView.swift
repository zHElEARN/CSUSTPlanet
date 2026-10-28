//
//  RootLayoutView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/29.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

@MainActor
private let featureSections: [(title: String, items: [FeatureTabID])] = [
    ("课程学习", [.courseSchedule, .courses, .assignments, .chaoxingAssignments]),
    ("成绩与考试", [.gradeQuery, .gradeAnalysis, .examSchedule]),
    ("校园工具", [.electricityQuery, .availableClassroom, .campusMap, .schoolCalendar, .electricityRecharge, .webVPNConverter, .eval]),
    ("大学物理实验", [.physicsExperimentSchedule, .physicsExperimentGrade]),
    ("其他考试查询", [.cet, .mandarin, .ncre]),
]

struct RootLayoutView: View {
    @Bindable var router: Router
    @Bindable var globalManager = GlobalManager.shared

    #if os(macOS)
    private let isCompact = false
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isCompact: Bool {
        horizontalSizeClass == .compact || UIDevice.current.userInterfaceIdiom == .phone
    }
    #endif

    var body: some View {
        Group {
            if #available(iOS 18.0, macOS 15.0, *) {
                tabLayout
            } else {
                adaptiveLayout
            }
        }
        .onChange(of: isCompact, initial: true) { oldValue, newValue in
            router.isCompact = newValue
            if oldValue != newValue {
                router.handleSizeClassChange(toCompact: newValue)
            }
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private var tabLayout: some View {
        TabView(selection: $router.selectedTab) {
            Tab("概览", systemImage: "rectangle.stack", value: AppTabItem.overview) {
                navigationStack(for: .overview) {
                    OverviewView()
                }
            }
            .badge(globalManager.unreadAnnouncementsCount)

            Tab("日程", systemImage: "calendar", value: AppTabItem.schedule) {
                navigationStack(for: .schedule) {
                    ScheduleView()
                }
            }

            if isCompact {
                Tab("功能", systemImage: "square.grid.2x2", value: AppTabItem.features) {
                    navigationStack(for: .features) {
                        FeaturesView()
                    }
                }

                Tab("我的", systemImage: "person", value: AppTabItem.profile) {
                    navigationStack(for: .profile) {
                        ProfileView()
                    }
                }
            } else {
                Tab("我的", systemImage: "person", value: AppTabItem.profile) {
                    navigationStack(for: .profile) {
                        ProfileView()
                    }
                }

                ForEach(featureSections.indices, id: \.self) { index in
                    TabSection(featureSections[index].title) {
                        ForEach(featureSections[index].items, id: \.self) { item in
                            Tab(item.name, systemImage: item.systemImage, value: AppTabItem.feature(item)) {
                                navigationStack(for: .feature(item)) {
                                    featureRootView(for: item)
                                }
                            }
                        }
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    @available(iOS 17.0, macOS 14.0, *)
    @ViewBuilder
    private var adaptiveLayout: some View {
        if isCompact {
            TabView(selection: $router.selectedTab) {
                navigationStack(for: .overview) {
                    OverviewView()
                }
                .tabItem { Label("概览", systemImage: "rectangle.stack") }
                .tag(AppTabItem.overview)
                .badge(globalManager.unreadAnnouncementsCount)

                navigationStack(for: .schedule) {
                    ScheduleView()
                }
                .tabItem { Label("日程", systemImage: "calendar") }
                .tag(AppTabItem.schedule)

                navigationStack(for: .features) {
                    FeaturesView()
                }
                .tabItem { Label("功能", systemImage: "square.grid.2x2") }
                .tag(AppTabItem.features)

                navigationStack(for: .profile) {
                    ProfileView()
                }
                .tabItem { Label("我的", systemImage: "person") }
                .tag(AppTabItem.profile)
            }
        } else {
            NavigationSplitView {
                List(
                    selection: Binding<AppTabItem?>(
                        get: { router.selectedTab },
                        set: { newValue in
                            if let newValue {
                                router.selectedTab = newValue
                            }
                        }
                    )
                ) {
                    Section {
                        sidebarRow(
                            title: "概览",
                            systemImage: "rectangle.stack",
                            tab: .overview,
                            badgeCount: globalManager.unreadAnnouncementsCount
                        )
                        sidebarRow(title: "日程", systemImage: "calendar", tab: .schedule)
                        sidebarRow(title: "我的", systemImage: "person", tab: .profile)
                    }

                    ForEach(featureSections.indices, id: \.self) { index in
                        Section(featureSections[index].title) {
                            ForEach(featureSections[index].items, id: \.self) { item in
                                sidebarRow(
                                    title: item.name,
                                    systemImage: item.systemImage,
                                    tab: .feature(item)
                                )
                            }
                        }
                    }
                }
                .navigationTitle("云岭星球")
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 250)
                #endif
            } detail: {
                switch router.selectedTab {
                case .overview:
                    navigationStack(for: .overview) {
                        OverviewView()
                    }
                case .schedule:
                    navigationStack(for: .schedule) {
                        ScheduleView()
                    }
                case .profile:
                    navigationStack(for: .profile) {
                        ProfileView()
                    }
                case .feature(let feature):
                    navigationStack(for: .feature(feature)) {
                        featureRootView(for: feature)
                    }
                default:
                    ContentUnavailableView("请选择项目", systemImage: "list.bullet")
                }
            }
        }
    }

    private func navigationStack<Root: View>(for tab: AppTabItem, @ViewBuilder root: () -> Root) -> some View {
        NavigationStack(path: $router[pathFor: tab]) {
            root().withAppRouter()
        }
    }

    @ViewBuilder
    private func sidebarRow(title: String, systemImage: String, tab: AppTabItem, badgeCount: Int? = nil) -> some View {
        let baseRow = Label(title, systemImage: systemImage)
            .tag(tab)
            .id(tab)

        if let badgeCount, badgeCount > 0 {
            baseRow.badge(badgeCount)
        } else {
            baseRow
        }
    }

    @ViewBuilder
    private func featureRootView(for feature: FeatureTabID) -> some View {
        feature.rootRoute.destinationView
    }
}
