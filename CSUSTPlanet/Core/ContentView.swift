//
//  ContentView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/7.
//

import SwiftUI

struct ContentView: View {
    @Bindable var globalManager = GlobalManager.shared
    @Bindable var authManager = AuthManager.shared

    @State private var router = Router()

    var body: some View {
        DatabaseStatusView {
            RootLayoutView(router: router)
                .onChange(of: router.currentTrackPath) { oldValue, newValue in
                    TrackHelper.shared.views(path: newValue)
                }
        }
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
        .onReceive(LifecycleManager.shared.events) { event in
            switch event {
            case .didBecomeActive:
                TrackHelper.shared.event(category: "Lifecycle", action: "Active")
            case .didBecomeInactive:
                TrackHelper.shared.event(category: "Lifecycle", action: "Inactive")
            case .didEnterBackground:
                TrackHelper.shared.event(category: "Lifecycle", action: "Background")
            }
        }
        .sheet(isPresented: $authManager.isCaptchaPresented) {
            CaptchaInputView()
        }
        #if os(iOS)
        .preferredColorScheme(globalManager.preferredColorScheme)
        #endif
        .sheet(isPresented: globalManager.isUserAgreementShowing) {
            NavigationStack {
                UserAgreementView(isButtonPresented: true)
            }
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $globalManager.isAppUpdateSheetPresented) {
            AppUpdateSheetView()
        }
        .onOpenURL { url in
            router.handleDeepLink(url)
        }
    }
}
