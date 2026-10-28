//
//  GradeQuerySection.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/6/18.
//

import CSUSTKit
import SwiftUI

struct GradeQuerySection: View {
    let semester: String
    let grades: [EduHelper.CourseGrade]
    @State private var isExpanded: Bool = true
    let semesterGPA: Double
    let isSelectionMode: Bool
    @Binding var selectedCourseIDs: Set<String>

    var body: some View {
        CustomGroupBox {
            VStack {
                HStack {
                    Image(systemName: "chevron.right")
                        .frame(width: 16, height: 16, alignment: .leading)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0), anchor: .center)

                    Text(semester)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(grades.count)门课程")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("学期GPA: \(semesterGPA, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }

                if isExpanded {
                    ForEach(grades, id: \.courseID) { grade in
                        Divider()
                        GradeQueryGradeRow(
                            courseGrade: grade,
                            isSelectionMode: isSelectionMode,
                            isSelected: Binding(
                                get: { selectedCourseIDs.contains(grade.courseID) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedCourseIDs.insert(grade.courseID)
                                    } else {
                                        selectedCourseIDs.remove(grade.courseID)
                                    }
                                }
                            ).withAnimation()
                        )
                    }
                }
            }
        }
    }
}
