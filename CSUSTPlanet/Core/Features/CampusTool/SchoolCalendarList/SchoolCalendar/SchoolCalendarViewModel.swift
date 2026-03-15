//
//  SchoolCalendarViewModel.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2025/7/11.
//

import Alamofire
import SwiftUI

@Observable
class SchoolCalendarViewModel {
    var config: ConfigData?
    var weeks: [WeekRow] = []
    var weekSpans: [SpanData] = []
    var monthSpans: [SpanData] = []
    var notes: [String] = []

    var isLoading: Bool = false
    var isShowingError: Bool = false
    var errorMessage: String = ""

    // 固定尺寸
    let headerHeight: CGFloat = 36
    let rowHeight: CGFloat = 46
    let dayNames = ["日", "一", "二", "三", "四", "五", "六"]

    private let monthNames = [
        1: "一月", 2: "二月", 3: "三月", 4: "四月",
        5: "五月", 6: "六月", 7: "七月", 8: "八月",
        9: "九月", 10: "十月", 11: "十一月", 12: "十二月",
    ]

    private let circleNumbers = ["①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩"]

    @MainActor
    func loadConfig(semester: String) async {
        isLoading = true
        isShowingError = false

        do {
            let decodedConfig = try await AF.request("\(Constants.backendHost)/config/semester-calendars/\(semester)")
                .serializingDecodable(ConfigData.self).value
            self.config = decodedConfig
            generateCalendar(from: decodedConfig)
        } catch {
            debugPrint(error)
            self.isShowingError = true
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func generateCalendar(from config: ConfigData) {
        let fmt = ISO8601DateFormatter()

        guard let startDate = fmt.date(from: config.calendarStart),
            let endDate = fmt.date(from: config.calendarEnd),
            let semesterStart = fmt.date(from: config.semesterStart),
            let semesterEnd = fmt.date(from: config.semesterEnd)
        else { return }

        let cal = Calendar.current

        let semStartWeekday = cal.component(.weekday, from: semesterStart)
        let semStartSunday = cal.date(byAdding: .day, value: -(semStartWeekday - 1), to: semesterStart)!

        let semEndWeekday = cal.component(.weekday, from: semesterEnd)
        let semEndSaturday = cal.date(byAdding: .day, value: 7 - semEndWeekday, to: semesterEnd)!

        var currentTemp = startDate
        var tempWeeks: [WeekRow] = []
        var rowIdx = 1

        while currentTemp <= endDate {
            let currentWeekSunday = currentTemp
            let currentWeekSaturday = cal.date(byAdding: .day, value: 6, to: currentTemp)!

            var weekInfo = WeekRow(id: rowIdx, month: cal.component(.month, from: currentTemp), computedWeekNumber: nil, days: [])

            if currentWeekSaturday >= semStartSunday && currentWeekSunday <= semEndSaturday {
                let diff = cal.dateComponents([.day], from: semStartSunday, to: currentWeekSunday).day ?? 0
                weekInfo.computedWeekNumber = (diff / 7) + 1
            }

            for i in 0..<7 {
                let isWeekend = (i == 0 || i == 6)
                let yyyy = cal.component(.year, from: currentTemp)
                let mm = String(format: "%02d", cal.component(.month, from: currentTemp))

                weekInfo.days.append(
                    DayData(
                        day: cal.component(.day, from: currentTemp),
                        isWeekend: isWeekend,
                        monthKey: "\(yyyy)-\(mm)"
                    ))
                currentTemp = cal.date(byAdding: .day, value: 1, to: currentTemp)!
            }
            tempWeeks.append(weekInfo)
            rowIdx += 1
        }
        self.weeks = tempWeeks

        var tempWeekSpans: [SpanData] = []
        var r = 1
        while r <= tempWeeks.count {
            if let custom = config.customWeekRanges.first(where: { $0.startRow == r }) {
                let rowCount = custom.endRow - custom.startRow + 1
                tempWeekSpans.append(SpanData(text: custom.content, rowCount: rowCount, isCustom: true))
                r = custom.endRow + 1
            } else {
                let text = tempWeeks[r - 1].computedWeekNumber != nil ? "\(tempWeeks[r-1].computedWeekNumber!)" : ""
                tempWeekSpans.append(SpanData(text: text, rowCount: 1, isCustom: false))
                r += 1
            }
        }
        self.weekSpans = tempWeekSpans

        var tempMonthSpans: [SpanData] = []
        if !tempWeeks.isEmpty {
            var currentMonth = tempWeeks[0].month
            var currentCount = 0
            for week in tempWeeks {
                if week.month == currentMonth {
                    currentCount += 1
                } else {
                    tempMonthSpans.append(SpanData(text: monthNames[currentMonth] ?? "", rowCount: currentCount, isCustom: false))
                    currentMonth = week.month
                    currentCount = 1
                }
            }
            if currentCount > 0 {
                tempMonthSpans.append(SpanData(text: monthNames[currentMonth] ?? "", rowCount: currentCount, isCustom: false))
            }
        }
        self.monthSpans = tempMonthSpans

        var tempNotes = Array(repeating: "", count: tempWeeks.count)
        var sequenceNumber = 1

        for note in config.notes {
            let rIndex = note.row - 1
            if rIndex >= 0 && rIndex < tempWeeks.count {
                var text = note.content
                if note.needNumber == true {
                    let prefix = sequenceNumber <= 10 ? circleNumbers[sequenceNumber - 1] : "\(sequenceNumber)"
                    text = "\(prefix) \(text)"
                    sequenceNumber += 1
                }
                tempNotes[rIndex] = text
            }
        }
        self.notes = tempNotes
    }
}

extension SchoolCalendarViewModel {
    // MARK: - 配置文件模型

    struct ConfigData: Codable {
        let semesterCode: String
        let title: String
        let subtitle: String
        let calendarStart: String
        let calendarEnd: String
        let semesterStart: String
        let semesterEnd: String
        let notes: [NoteConfig]
        let customWeekRanges: [CustomWeekRange]
    }

    struct NoteConfig: Codable {
        let row: Int
        let content: String
        let needNumber: Bool?
    }

    struct CustomWeekRange: Codable {
        let startRow: Int
        let endRow: Int
        let content: String
    }

    // MARK: - 视图渲染用到的数据模型

    struct DayData: Identifiable {
        let id = UUID()
        let day: Int
        let isWeekend: Bool
        let monthKey: String
    }

    struct WeekRow: Identifiable {
        let id: Int
        let month: Int
        var computedWeekNumber: Int?
        var days: [DayData]
    }

    struct SpanData: Identifiable {
        let id = UUID()
        let text: String
        let rowCount: Int
        let isCustom: Bool
    }
}
