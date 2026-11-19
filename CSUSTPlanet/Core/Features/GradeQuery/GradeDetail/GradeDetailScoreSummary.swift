//
//  GradeDetailScoreSummary.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import SwiftUI

struct GradeDetailScoreSummary: View {
    let params: GradeDetailParams

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(params.courseName)
                .font(.largeTitle)
                .bold()
                .padding(.horizontal)

            HStack(alignment: .top, spacing: 16) {
                GradeDetailScoreItem(value: "\(params.grade)", label: "总成绩", color: ColorUtil.dynamicColor(grade: Double(params.grade)))
                GradeDetailScoreItem(value: String(format: "%.1f", params.gradePoint), label: "绩点", color: ColorUtil.dynamicColor(point: params.gradePoint))
                GradeDetailScoreItem(value: String(format: "%.1f", params.credit), label: "学分", color: .primary)
                GradeDetailScoreItem(value: "\(params.totalHours)", label: "学时", color: .primary)
            }
            .padding(.horizontal)
        }
    }
}

private struct GradeDetailScoreItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
