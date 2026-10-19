//
//  ElectricityRechargeView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/10/13.
//

import CSUSTKit
import SwiftUI

struct ElectricityRechargeView: View {
    @State private var webViewController = WebViewController()

    var baseURL: URL {
        if AuthManager.shared.isSSOLoggedIn {
            URL(string: "https://hxyxh5.csust.edu.cn/berserker-auth/cas/login/wisedu?targetUrl=https://hxyxh5.csust.edu.cn/plat/?name=loginTransit")!
        } else {
            URL(string: "https://hxyxh5.csust.edu.cn/plat/shouyeUser")!
        }
    }

    var vpnURL: URL { try! WebVPNHelper.encryptURL(baseURL) }

    var url: URL {
        if MMKVHelper.GlobalManager.isWebVPNModeEnabled {
            vpnURL
        } else {
            baseURL
        }
    }

    var body: some View {
        WebView(
            url: url,
            cookies: CookieHelper.shared.currentCookies,
            controller: webViewController
        )
        .inlineToolbarTitle()
        .navigationTitle("电费充值")
        .toolbar {
            WebViewControlsToolbar(controller: webViewController)
        }
    }
}

#Preview {
    ElectricityRechargeView()
}
