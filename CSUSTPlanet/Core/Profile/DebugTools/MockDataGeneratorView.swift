//
//  MockDataGeneratorView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/27.
//

#if DEBUG
import CSUSTKit
import SwiftUI

struct MockDataGeneratorView: View {
    @State private var todoAssignmentsCacheDescription = ""

    var body: some View {
        Form {
            Section {
                Button("清空待提交作业数据（nil）") {
                    MMKVHelper.TodoAssignments.cache = nil
                    refreshTodoAssignmentsCacheDescription()
                }

                Button("清空待提交作业数据（空数组）") {
                    MMKVHelper.TodoAssignments.cache = Cached(cachedAt: .now, value: [])
                    refreshTodoAssignmentsCacheDescription()
                }

                Button("生成两个模拟待提交作业") {
                    MMKVHelper.TodoAssignments.cache = Cached(
                        cachedAt: .now,
                        value: MockTodoAssignmentsFactory.makeTwoAssignmentsData()
                    )
                    refreshTodoAssignmentsCacheDescription()
                }
            } header: {
                Text("待提交作业")
            } footer: {
                Text(todoAssignmentsCacheDescription)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("模拟数据生成")
        .onAppear(perform: refreshTodoAssignmentsCacheDescription)
    }

    private func refreshTodoAssignmentsCacheDescription() {
        guard let cache = MMKVHelper.TodoAssignments.cache else {
            todoAssignmentsCacheDescription = "当前状态：nil"
            return
        }

        let assignmentCount = cache.value.reduce(into: 0) { partialResult, item in
            partialResult += item.assignments.count
        }

        todoAssignmentsCacheDescription = "当前状态：\(cache.value.count) 门课程，\(assignmentCount) 个作业，缓存时间 \(cache.cachedAt.formatted(date: .abbreviated, time: .standard))"
    }
}

private enum MockTodoAssignmentsFactory {
    static func makeTwoAssignmentsData(referenceDate: Date = .now) -> [TodoAssignmentsData] {
        [
            TodoAssignmentsData(
                course: .init(
                    id: "mock-course-todo-1",
                    name: "程序设计与算法分析",
                    number: "CS202",
                    department: "计算机学院",
                    teacher: "陈老师"
                ),
                assignments: [
                    .init(
                        id: 10001,
                        title: "实验报告：图的遍历",
                        publisher: "陈老师",
                        canSubmit: true,
                        submitStatus: false,
                        deadline: referenceDate.addingTimeInterval(6 * 3600),
                        startTime: referenceDate.addingTimeInterval(-2 * 24 * 3600)
                    )
                ]
            ),
            TodoAssignmentsData(
                course: .init(
                    id: "mock-course-todo-2",
                    name: "大学物理实验",
                    number: "PH114",
                    department: "理学院",
                    teacher: "刘老师"
                ),
                assignments: [
                    .init(
                        id: 10002,
                        title: "实验数据分析作业",
                        publisher: "刘老师",
                        canSubmit: true,
                        submitStatus: false,
                        deadline: referenceDate.addingTimeInterval(36 * 3600),
                        startTime: referenceDate.addingTimeInterval(-3 * 24 * 3600)
                    )
                ]
            ),
        ]
    }
}
#endif
