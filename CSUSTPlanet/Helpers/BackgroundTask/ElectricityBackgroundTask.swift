//
//  ElectricityBackgroundTask.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/1/17.
//

#if os(iOS)

import BackgroundTasks
import Foundation
import OSLog

struct ElectricityBackgroundTask: BackgroundTaskProvider {
    let identifier: String = Constants.backgroundElectricityID

    let defaultInterval: TimeInterval = 6 * 60 * 60
    let availableIntervals: [TimeInterval] = [
        1 * 60 * 60,
        3 * 60 * 60,
        6 * 60 * 60,
        12 * 60 * 60,
    ]

    let title: String = "查询宿舍电量"
    let description: String = "在后台查询当前收藏宿舍电量，并在电量有更新时发送通知"

    func handle(task: BGAppRefreshTask) {
        task.expirationHandler = {
            // TODO: 处理后台任务超时
            Logger.backgroundTaskHelper.debug("后台任务超时: \(self.identifier)")
            task.setTaskCompleted(success: false)
        }
        // TODO: 获取电量
        Logger.backgroundTaskHelper.debug("获取电量")
        task.setTaskCompleted(success: true)
    }
}
#endif
