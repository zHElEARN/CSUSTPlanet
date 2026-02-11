//
//  GradesPage.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import CSUSTKit
import SwiftUI

struct GradesPage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("学业成绩")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                Group {
                    StatCard(title: "年度 GPA", value: String(format: "%.2f", data.annualGPA))
                    StatCard(title: "总学分", value: String(format: "%.1f", data.totalCredits))
                    HStack {
                        StatCard(title: "考试课", value: "\(data.examCount)")
                        StatCard(title: "考查课", value: "\(data.assessmentCount)")
                    }
                }

                if !data.highestGradeCourses.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最高分课程")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(data.highestGradeCourses, id: \.courseID) { course in
                            HStack {
                                Text(course.courseName)
                                    .font(.headline)
                                Spacer()
                                Text("\(course.grade)")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 10) {
                    CourseListView(title: "满绩科目", courses: data.fullGradePointCourses)
                    CourseListView(title: "刚好及格", courses: data.justPassedCourses)
                    CourseListView(title: "挂科科目", courses: data.failedCourses)
                }
                .padding()
            }
        }
    }
}
