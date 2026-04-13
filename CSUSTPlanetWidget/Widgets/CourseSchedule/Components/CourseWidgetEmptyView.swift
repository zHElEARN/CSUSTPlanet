//
//  CourseWidgetEmptyView.swift
//  CSUSTPlanetWidgetExtension
//
//  Created by Zachary Liu on 2026/2/25.
//

import Foundation
import SwiftUI

struct CourseWidgetEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title)
                .foregroundStyle(.gray.opacity(0.8))

            VStack(spacing: 4) {
                Text(CourseScheduleUtil.emptyCourseScheduleText)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("请先在 App 中查询课表")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
