//
//  ExamSchedulePreviewData.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

import CSUSTKit
import Foundation

enum ExamSchedulePreviewData {
    static let exams: [EduHelper.Exam] = [
        makeExam(
            courseID: "MATH1001",
            courseName: "高等数学A(一)",
            teacher: "李老师",
            examTime: "2025-12-30 09:00-11:00",
            startTimeOffset: -1_728_000,
            examRoom: "云塘校区 综合教学楼 A101",
            seatNumber: "12",
            admissionTicketNumber: "20251230001",
            remarks: "已结束的考试样例"
        ),
        makeExam(
            courseID: "CS1001",
            courseName: "程序设计基础",
            teacher: "王老师",
            examTime: "2026-01-05 14:00-16:00",
            startTimeOffset: 259_200,
            examRoom: "云塘校区 综合教学楼 B203",
            seatNumber: "08",
            admissionTicketNumber: "20260105002",
            remarks: ""
        ),
        makeExam(
            courseID: "PHYS1001",
            courseName: "大学物理实验",
            teacher: "张老师",
            examTime: "2026-01-12 09:00-11:00",
            startTimeOffset: 864_000,
            examRoom: "金盆岭校区 电苑楼 301",
            seatNumber: "",
            admissionTicketNumber: "",
            remarks: "请携带学生证"
        ),
    ]

    private static func makeExam(
        courseID: String,
        courseName: String,
        teacher: String,
        examTime: String,
        startTimeOffset: TimeInterval,
        examRoom: String,
        seatNumber: String,
        admissionTicketNumber: String,
        remarks: String
    ) -> EduHelper.Exam {
        let startTime = Date.now.addingTimeInterval(startTimeOffset)
        return EduHelper.Exam(
            campus: "云塘校区",
            session: "第一场",
            courseID: courseID,
            courseName: courseName,
            teacher: teacher,
            examTime: examTime,
            examStartTime: startTime,
            examEndTime: startTime.addingTimeInterval(7200),
            examRoom: examRoom,
            seatNumber: seatNumber,
            admissionTicketNumber: admissionTicketNumber,
            remarks: remarks
        )
    }
}
