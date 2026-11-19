//
//  GradeDetailInfoSection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import SwiftUI

struct GradeDetailInfoSection: View {
    let params: GradeDetailParams

    var body: some View {
        CustomGroupBox {
            VStack(alignment: .leading, spacing: 12) {
                GradeDetailInfoRow(label: "课程编号", value: params.courseID)
                GradeDetailInfoRow(label: "开课学期", value: params.semester)
                if !params.groupName.isEmpty {
                    GradeDetailInfoRow(label: "分组名", value: params.groupName)
                }
                GradeDetailInfoRow(label: "修读方式", value: params.studyMode)
                GradeDetailInfoRow(label: "课程性质", value: params.courseNature.rawValue)
                if !params.courseCategory.isEmpty {
                    GradeDetailInfoRow(label: "课程类别", value: params.courseCategory)
                }
                GradeDetailInfoRow(label: "课程属性", value: params.courseAttribute)
                GradeDetailInfoRow(label: "考核方式", value: params.assessmentMethod)
                GradeDetailInfoRow(label: "考试性质", value: params.examNature)
            }
        }
    }
}

private struct GradeDetailInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.callout)
                .multilineTextAlignment(.trailing)
        }
    }
}
