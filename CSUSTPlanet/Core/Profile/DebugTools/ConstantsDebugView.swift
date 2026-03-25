//
//  ConstantsDebugView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/25.
//

#if DEBUG
import SwiftUI

struct ConstantsDebugView: View {
    private var items: [(name: String, value: String)] {
        [
            ("appGroupID", Constants.appGroupID),
            ("iCloudID", Constants.iCloudID),
            ("keychainGroup", Constants.keychainGroup),
            ("appBundleID", Constants.appBundleID),
            ("widgetBundleID", Constants.widgetBundleID),
            ("sharedContainerURL", Constants.sharedContainerURL.path),
            ("mmkvDirectoryURL", Constants.mmkvDirectoryURL.path),
            ("mmkvID", Constants.mmkvID),
            ("grdbDirectoryURL", Constants.grdbDirectoryURL.path),
            ("grdbDatabaseURL", Constants.grdbDatabaseURL.path),
            ("backendHost", Constants.backendHost),
            ("matomoURL", Constants.matomoURL),
            ("matomoUserIDSalt", Constants.matomoUserIDSalt),
            ("matomoDimensionIDAppFullVersion", Constants.matomoDimensionIDAppFullVersion),
            ("matomoSiteID", Constants.matomoSiteID),
            ("backgroundID", Constants.backgroundID),
            ("sentryDSN", Constants.sentryDSN),
            ("dbChangedNotification", Constants.dbChangedNotification),
            ("dbChangedCFNotificationName", Constants.dbChangedCFNotificationName.rawValue as String),
            ("dbChangedCFString", Constants.dbChangedCFString as String),
        ]
    }

    var body: some View {
        List(items, id: \.name) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                Text(item.value)
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Constant常量")
    }
}
#endif
