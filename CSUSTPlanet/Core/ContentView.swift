//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import AlertToast
import SwiftUI

#if os(macOS)
import AppKit
#endif

struct FeatureItem: Identifiable {
    let id: FeatureTabID

    init(id: FeatureTabID) {
        self.id = id
    }

    var title: String { id.name }
    var icon: String { id.systemImage }
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
            FeatureItem(id: .courseSchedule),
            FeatureItem(id: .gradeQuery),
            FeatureItem(id: .examSchedule),
            FeatureItem(id: .gradeAnalysis),
        ]
    ),
    FeatureSection(
        title: "网络课程中心",
        items: [
            FeatureItem(id: .courses),
            FeatureItem(id: .urgentCourses),
        ]
    ),
    FeatureSection(
        title: "校园工具",
        items: [
            FeatureItem(id: .electricityQuery),
            FeatureItem(id: .availableClassroom),
            FeatureItem(id: .campusMap),
            FeatureItem(id: .schoolCalendar),
            FeatureItem(id: .electricityRecharge),
            FeatureItem(id: .webVPNConverter),
        ]
    ),
    FeatureSection(
        title: "大学物理实验",
        items: [
            FeatureItem(id: .physicsExperimentSchedule),
            FeatureItem(id: .physicsExperimentGrade),
        ]
    ),
    FeatureSection(
        title: "其他考试查询",
        items: [
            FeatureItem(id: .cet),
            FeatureItem(id: .mandarin),
        ]
    ),
]

struct ContentView: View {
    @Bindable var globalManager = GlobalManager.shared
    @Bindable var authManager = AuthManager.shared

    @Environment(\.colorScheme) private var colorScheme
    @State private var router = Router()

    #if os(macOS)
    private let isCompactEnv = false
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompactEnv: Bool { horizontalSizeClass == .compact }
    #endif

    var body: some View {
        Group {
            if globalManager.hasDatabaseFatalError {
                VStack(spacing: 16) {
                    Text("数据库异常，请联系开发者")
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text(globalManager.databaseFatalErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text("你可以复制错误信息并反馈给开发者")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let emailURL = URL(string: "mailto:developer@zhelearn.com") {
                        Link("联系邮箱：developer@zhelearn.com", destination: emailURL)
                    }

                    Button("复制错误信息") {
                        let text = globalManager.databaseFatalErrorMessage
                        guard !text.isEmpty else { return }
                        #if os(iOS)
                        PlatformPasteboard.general.string = text
                        #elseif os(macOS)
                        PlatformPasteboard.general.clearContents()
                        PlatformPasteboard.general.setString(text, forType: .string)
                        #endif
                    }
                    .buttonStyle(.bordered)

                    Button("退出应用") {
                        exit(0)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if globalManager.isMigratingToGRDB {
                VStack(spacing: 20) {
                    ProgressView()
                        .controlSize(.large)
                    Text("正在优化本地数据库...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task {
                    await globalManager.migrateDatabaseIfNeeded()
                }
            } else {
                Group {
                    if #available(iOS 18.0, macOS 15.0, *) {
                        modernLayout
                    } else {
                        legacyLayout
                    }
                }
                .onChange(of: isCompactEnv, initial: true) { oldValue, newValue in
                    router.isCompact = newValue
                    if oldValue != newValue {
                        router.handleSizeClassChange(toCompact: newValue)
                    }
                }
                .onChange(of: router.currentTrackPath) { oldValue, newValue in
                    TrackHelper.shared.views(path: newValue)
                }
            }
        }
        .trackRoot("App")
        .environment(router)

        #if os(iOS)
        .apply { view in
            if #available(iOS 26.0, macOS 26.0, *) {
                view.tabBarMinimizeBehavior(.onScrollDown)
            } else {
                view
            }
        }
        #endif

        // MARK: 全局Toast状态

        .toast(isPresenting: $authManager.isSSOInfoPresented) {
            AlertToast(displayMode: .hud, type: .systemImage("info.circle.fill", .blue), title: authManager.ssoInfo)
        }
        .toast(isPresenting: $authManager.isSSOErrorPresented) {
            AlertToast(displayMode: .hud, type: .error(.red), title: authManager.ssoError)
        }
        .toast(isPresenting: $authManager.isEducationInfoPresented) {
            AlertToast(displayMode: .hud, type: .systemImage("info.circle.fill", .blue), title: authManager.educationInfo)
        }
        .toast(isPresenting: $authManager.isEducationErrorPresented) {
            AlertToast(displayMode: .hud, type: .error(.red), title: authManager.educationError)
        }
        .toast(isPresenting: $authManager.isMoocInfoPresented) {
            AlertToast(displayMode: .hud, type: .systemImage("info.circle.fill", .blue), title: authManager.moocInfo)
        }
        .toast(isPresenting: $authManager.isMoocErrorPresented) {
            AlertToast(displayMode: .hud, type: .error(.red), title: authManager.moocError)
        }

        // MARK: - 主题设置 & 用户协议弹窗

        #if os(iOS)
        .preferredColorScheme(globalManager.preferredColorScheme)
        #endif
        .sheet(isPresented: globalManager.isOnboardingSheetShowing) {
            OnboardingView(onSkip: globalManager.completeOnboarding, presentingColorScheme: colorScheme)
        }
        .sheet(isPresented: globalManager.isUserAgreementShowing) {
            UserAgreementView(isButtonPresented: true).interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $globalManager.isAppUpdateSheetPresented) {
            AppUpdateSheetView()
        }

        // Widget deep links are temporarily disabled during the navigationDestination migration.
        // .onOpenURL { url in
        //     guard url.scheme == "csustplanet", url.host == "widgets" else { return }
        //     router.deepLinkToOverview()
        //     switch url.pathComponents.dropFirst().first {
        //     case "electricity":
        //         router.deepLinkTo(feature: .electricityQuery)
        //     case "gradeAnalysis":
        //         router.deepLinkTo(feature: .gradeAnalysis)
        //     case "courseSchedule":
        //         router.deepLinkTo(feature: .courseSchedule)
        //     case "todoAssignments":
        //         router.deepLinkTo(feature: .urgentCourses)
        //     default:
        //         break
        //     }
        // }
    }

    // MARK: - Modern Layout

    @available(iOS 18.0, macOS 15.0, *)
    private var modernLayout: some View {
        TabView(selection: $router.selectedTab) {
            Tab("概览", systemImage: "rectangle.stack", value: AppTabItem.overview) {
                navigationStack(for: .overview) {
                    OverviewView()
                }
            }
            .badge(globalManager.unreadAnnouncementsCount)

            if router.isCompact {
                Tab("全部功能", systemImage: "square.grid.2x2", value: AppTabItem.features) {
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

                ForEach(featureSections) { section in
                    buildTabSection(for: section)
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }

    @available(iOS 18.0, macOS 15.0, *)
    private func buildTabSection(for section: FeatureSection) -> some TabContent<AppTabItem> {
        return TabSection(section.title) {
            ForEach(section.items) { item in
                buildFeatureTab(for: item)
            }
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private func buildFeatureTab(for item: FeatureItem) -> some TabContent<AppTabItem> {
        return Tab(item.title, systemImage: item.icon, value: AppTabItem.feature(item.id)) {
            navigationStack(for: .feature(item.id)) {
                featureRootView(for: item.id)
            }
        }
    }

    // MARK: - Legacy Layout

    @available(iOS 17.0, macOS 14.0, *)
    @ViewBuilder
    private var legacyLayout: some View {
        if router.isCompact {
            TabView(selection: $router.selectedTab) {
                navigationStack(for: .overview) {
                    OverviewView()
                }
                .tabItem { Label("概览", systemImage: "rectangle.stack") }
                .tag(AppTabItem.overview)
                .badge(globalManager.unreadAnnouncementsCount)

                navigationStack(for: .features) {
                    FeaturesView()
                }
                .tabItem { Label("全部功能", systemImage: "square.grid.2x2") }
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
                        Label("概览", systemImage: "rectangle.stack")
                            .tag(AppTabItem.overview)
                            .badge(globalManager.unreadAnnouncementsCount)
                        Label("我的", systemImage: "person")
                            .tag(AppTabItem.profile)
                    }

                    ForEach(featureSections) { section in
                        Section(section.title) {
                            ForEach(section.items) { item in
                                Label(item.title, systemImage: item.icon)
                                    .tag(AppTabItem.feature(item.id))
                            }
                        }
                    }
                }
                .navigationTitle("长理星球")
            } detail: {
                switch router.selectedTab {
                case .overview:
                    navigationStack(for: .overview) {
                        OverviewView()
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
            root()
                .withAppRouter()
        }
    }

    @ViewBuilder
    private func featureRootView(for feature: FeatureTabID) -> some View {
        feature.rootRoute.destinationView
    }
}
