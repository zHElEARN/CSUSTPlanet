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
        TabView(selection: $globalManager.selectedTab) {
            OverviewView()
                .tag(TabItem.overview)
            FeaturesView()
                .tag(TabItem.features)
            ProfileView()
                .tag(TabItem.profile)
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
