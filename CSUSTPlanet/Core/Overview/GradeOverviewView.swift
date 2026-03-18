//
//  GradeOverviewView.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/12/12.
//

import CSUSTKit
import SwiftUI

struct GradeOverviewView: View {
    @Bindable var viewModel: OverviewViewModel

    var body: some View {
        TrackLink(destination: GradeQueryView()) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Text("GPA")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let gradeAnalysis = viewModel.gradeAnalysis {
                    Text(String(format: "%.2f", gradeAnalysis.overallGPA))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorUtil.dynamicColor(point: gradeAnalysis.overallGPA))

                    Text("平均分: \(String(format: "%.1f", gradeAnalysis.overallAverageGrade))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("-.-")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("暂无数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            #if os(iOS)
            .background(Color(PlatformColor.secondarySystemGroupedBackground))
            #else
            .background(Color(PlatformColor.controlBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
