//
//  AnnualReviewView.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/2/11.
//

import CSUSTKit
import SwiftUI

struct AnnualReviewView: View {
    @StateObject private var viewModel = AnnualReviewViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("正在生成年度报告...")
                } else if let data = viewModel.reviewData {
                    TabView {
                        ProfilePage(data: data)
                            .tag(0)

                        TimeSchedulePage(data: data)
                            .tag(1)

                        SpacePeoplePage(data: data)
                            .tag(2)

                        if data.moocAvailable {
                            MoocPage(data: data)
                                .tag(3)
                        }
                        GradesPage(data: data)
                            .tag(4)

                        DormPage(data: data)
                            .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                } else {
                    ContentUnavailableView("无数据", systemImage: "xmark.bin")
                }
            }
            .navigationTitle("2025 年度报告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                viewModel.compute()
            }
        }
    }
}

// MARK: - Page 1: 个人信息
private struct ProfilePage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("个人信息")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    AnnualInfoRow(label: "姓名", value: data.name)
                    AnnualInfoRow(label: "拼音", value: data.namePinyin)
                    AnnualInfoRow(label: "学号", value: data.studentID)
                    AnnualInfoRow(label: "院系", value: data.department)
                    AnnualInfoRow(label: "专业", value: data.major)
                    AnnualInfoRow(label: "班级", value: data.className)
                    AnnualInfoRow(label: "入学日期", value: data.enrollmentDate)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                .padding()
            }
        }
    }
}

// MARK: - Page 2: 课程统计
private struct TimeSchedulePage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("课程统计")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(spacing: 15) {
                    StatCard(title: "总课程数", value: "\(data.totalCoursesCount)")
                    StatCard(title: "总学时", value: "\(data.totalStudyMinutes) 分钟")
                    StatCard(title: "早八次数", value: "\(data.earlyMorningCoursesCount)")
                    StatCard(title: "晚课次数", value: "\(data.eveningCoursesCount)")
                    StatCard(title: "周末上课次数", value: "\(data.weekendCoursesCount)")
                }
                .padding()
            }
        }
    }
}

// MARK: - Page 3: 上课地点与老师
private struct SpacePeoplePage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("常去地点与老师")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(alignment: .leading, spacing: 10) {
                    Text("上课常去地点 TOP")
                        .font(.headline)
                    RankingView(ranking: data.buildingFrequency, suffix: "次")

                    Divider()

                    Text("每日课程分布")
                        .font(.headline)
                    ClassFrequencyView(frequency: data.dailyClassFrequency)

                    Divider()

                    Text("上课常去老师 TOP")
                        .font(.headline)
                    RankingView(ranking: data.teacherRanking, suffix: "次")
                }
                .padding()
            }
        }
    }
}

// MARK: - Page 4: 网络课程中心
private struct MoocPage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("网络课程中心")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                VStack(spacing: 15) {
                    StatCard(title: "总在线时长", value: "\(data.moocTotalOnlineMinutes ?? 0) 分钟")
                    StatCard(title: "登录次数", value: "\(data.moocLoginCount ?? 0) 次")
                }
                .padding()
            }
        }
    }
}

// MARK: - Page 5: 学业成绩
private struct GradesPage: View {
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

// MARK: - Page 6: 宿舍生活
private struct DormPage: View {
    let data: AnnualReviewData

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("宿舍生活")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                ForEach(data.dormElectricityStats) { stat in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(stat.campusName) \(stat.buildingName) \(stat.room)")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("查询: \(stat.queryCount) 次")
                                Text("充电: \(stat.chargeCount) 次")
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("最高: \(String(format: "%.1f", stat.maxElectricity))")
                                Text("最低: \(String(format: "%.1f", stat.minElectricity))")
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                if data.dormElectricityStats.isEmpty {
                    Text("暂无宿舍数据")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Components

private struct AnnualInfoRow: View {
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

private struct StatCard: View {
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

private struct RankingView: View {
    let ranking: [String: Int]
    let suffix: String

    var body: some View {
        let sorted = ranking.sorted { $0.value > $1.value }.prefix(5)
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(sorted.indices), id: \.self) { index in
                let (key, value) = sorted[index]
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

private struct ClassFrequencyView: View {
    let frequency: [EduHelper.DayOfWeek: Int]

    var body: some View {
        let sorted = frequency.sorted { "\($0.key)" < "\($1.key)" }
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(sorted.indices), id: \.self) { index in
                let (key, value) = sorted[index]
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

private struct CourseListView: View {
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

#Preview {
    AnnualReviewView(isPresented: .constant(true))
}
