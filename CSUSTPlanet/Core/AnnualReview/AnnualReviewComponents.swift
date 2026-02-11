//
//  AnnualReviewComponents.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/12.
//

import CSUSTKit
import SwiftUI

struct AnnualInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct RankingView: View {
    let ranking: [String: Int]
    let suffix: String

    var body: some View {
        // Sort by frequency (value) descending, take top 5
        let sorted = ranking.sorted { $0.value > $1.value }.prefix(5)

        // Convert to array of (key, value) tuples for easier iteration with index
        let sortedArray = Array(sorted)

        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(sortedArray.indices), id: \.self) { index in
                let (key, value) = sortedArray[index]
                HStack {
                    Text("\(index + 1). \(key)")
                    Spacer()
                    Text("\(value) \(suffix)")
                }
                .font(.subheadline)
            }
        }
    }
}

struct ClassFrequencyView: View {
    let frequency: [EduHelper.DayOfWeek: Int]

    var body: some View {
        // Sort keys (days) alphabetically/logically if comparable, or just ensure consistent order
        let sorted = frequency.sorted { "\($0.key)" < "\($1.key)" }
        let sortedArray = Array(sorted)

        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(sortedArray.indices), id: \.self) { index in
                let (key, value) = sortedArray[index]
                HStack {
                    Text("\(String(describing: key))")
                    Spacer()
                    Text("\(value) 节")
                }
                .font(.subheadline)
            }
        }
    }
}

struct CourseListView: View {
    let title: String
    let courses: [EduHelper.CourseGrade]

    var body: some View {
        if !courses.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                Text("\(title) (\(courses.count))")
                    .font(.headline)
                    .padding(.top, 5)
                ForEach(courses, id: \.courseID) { course in
                    HStack {
                        Text(course.courseName)
                        Spacer()
                        Text("\(course.grade)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}
