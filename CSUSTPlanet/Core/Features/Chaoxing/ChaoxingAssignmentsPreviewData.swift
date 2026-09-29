//
//  ChaoxingAssignmentsPreviewData.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/9/28.
//

import CSUSTKit
import Foundation

enum ChaoxingAssignmentsPreviewData {
    static let assignments: [ChaoxingHelper.Assignment] = [
        ChaoxingHelper.Assignment(
            title: "第三章 关系数据库设计 课后作业",
            status: "未提交",
            courseName: "数据库系统",
            deadline: Date().addingTimeInterval(2 * 3600 + 30 * 60),
            iconURL: "https://p.ananas.chaoxing.com/star3/origin/example1.png",
            detailURL: "https://mooc1.chaoxing.com/work/1"
        ),
        ChaoxingHelper.Assignment(
            title: "实验四 查询优化",
            status: "未提交",
            courseName: "数据库系统",
            deadline: Date().addingTimeInterval(3 * 24 * 3600),
            iconURL: "https://p.ananas.chaoxing.com/star3/origin/example2.png",
            detailURL: "https://mooc1.chaoxing.com/work/2"
        ),
        ChaoxingHelper.Assignment(
            title: "第一章 绪论 课后作业",
            status: "已完成",
            courseName: "移动应用开发",
            deadline: nil,
            iconURL: "https://p.ananas.chaoxing.com/star3/origin/example3.png",
            detailURL: "https://mooc1.chaoxing.com/work/3"
        ),
        ChaoxingHelper.Assignment(
            title: "实验二 进程调度",
            status: "待批阅",
            courseName: "操作系统",
            deadline: nil,
            iconURL: "https://p.ananas.chaoxing.com/star3/origin/example4.png",
            detailURL: "https://mooc1.chaoxing.com/work/4"
        ),
        ChaoxingHelper.Assignment(
            title: "第二章 关系代数 课后作业",
            status: "已完成",
            courseName: "数据库系统",
            deadline: Date().addingTimeInterval(5 * 24 * 3600),
            iconURL: "https://p.ananas.chaoxing.com/star3/origin/example5.png",
            detailURL: "https://mooc1.chaoxing.com/work/5"
        ),
    ]
}
