//
//  DebugLogViewerView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/25.
//

#if DEBUG
import Darwin
import Foundation
import OSLog
import SwiftUI
import Observation

struct DebugLogEntry: Identifiable {
    enum Source: String {
        case oslog = "OSLog"
        case stdout = "stdout"
        case stderr = "stderr"
    }

    let id = UUID()
    let date: Date
    let source: Source
    let category: String?
    let level: String?
    let message: String
}

@Observable
@MainActor
final class DebugLogCenter {
    static let shared = DebugLogCenter()

    // 仅暴露这个属性供 SwiftUI 追踪更新
    private(set) var entries: [DebugLogEntry] = []

    @ObservationIgnored private let maxEntryCount = 3000
    // 注意：这里的 Constants 请确保你的项目中已定义
    @ObservationIgnored private let monitoredSubsystems = [Constants.appBundleID, Constants.widgetBundleID]

    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var processStartDate = Date()

    @ObservationIgnored private var stdoutOriginalFD: Int32 = -1
    @ObservationIgnored private var stderrOriginalFD: Int32 = -1
    @ObservationIgnored private var stdoutPipe: Pipe?
    @ObservationIgnored private var stderrPipe: Pipe?
    @ObservationIgnored private var stdoutBuffer = ""
    @ObservationIgnored private var stderrBuffer = ""

    // 记录 OSLog 的读取锚点
    @ObservationIgnored private var osLogPosition: OSLogPosition?
    // 使用 Hash 值防重，大幅节省内存
    @ObservationIgnored private var seenOSLogFingerprints: Set<Int> = []

    @ObservationIgnored private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private init() {}

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        processStartDate = Date()

        // 获取初始的 OSLog 锚点
        if let store = try? OSLogStore(scope: .currentProcessIdentifier) {
            osLogPosition = store.position(date: processStartDate)
        }

        installStdCapture()
        refreshOSLogs()
    }

    func refreshOSLogs() {
        let currentPosition = osLogPosition
        let startDate = processStartDate
        let subsystems = monitoredSubsystems

        // 将高开销的 OSLog 读取和字符串处理移至后台线程，防止阻塞主线程导致卡顿
        Task.detached {
            do {
                let store = try OSLogStore(scope: .currentProcessIdentifier)
                let position = currentPosition ?? store.position(date: startDate)
                let predicate = NSPredicate(
                    format: "subsystem == %@ OR subsystem == %@",
                    subsystems[0],
                    subsystems[1]
                )

                let sequence = try store.getEntries(at: position, matching: predicate)

                var tempEntries: [DebugLogEntry] = []
                var hashesToInsert: [Int] = []
                var latestDate: Date?

                for case let item as OSLogEntryLog in sequence {
                    latestDate = max(latestDate ?? item.date, item.date)

                    // 计算 Hash 值进行防重验证
                    let hash = "\(item.date.timeIntervalSince1970)-\(item.subsystem)-\(item.category)-\(item.level.rawValue)-\(item.composedMessage)".hashValue

                    tempEntries.append(
                        DebugLogEntry(
                            date: item.date,
                            source: .oslog,
                            category: item.category,
                            level: Self.osLogLevelName(item.level),
                            message: item.composedMessage
                        )
                    )
                    hashesToInsert.append(hash)
                }

                await MainActor.run { [weak self, tempEntries, hashesToInsert, latestDate] in
                    guard let self else { return }

                    for (index, entry) in tempEntries.enumerated() {
                        let hash = hashesToInsert[index]
                        if !self.seenOSLogFingerprints.contains(hash) {
                            self.seenOSLogFingerprints.insert(hash)
                            self.internalAppend(entry)
                        }
                    }

                    if self.seenOSLogFingerprints.count > self.maxEntryCount * 2 {
                        self.seenOSLogFingerprints.removeAll(keepingCapacity: true)
                    }

                    if let latestDate {
                        self.osLogPosition = store.position(date: latestDate.addingTimeInterval(0.001))
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.internalAppend(
                        DebugLogEntry(
                            date: .now,
                            source: .oslog,
                            category: "DebugLogCenter",
                            level: "error",
                            message: "读取OSLog失败: \(error.localizedDescription)"
                        )
                    )
                }
            }
        }
    }

    func exportText() -> String {
        entries
            .map { entry in
                var prefix = "[\(dateFormatter.string(from: entry.date))] [\(entry.source.rawValue)]"
                if let category = entry.category, !category.isEmpty {
                    prefix += " [\(category)]"
                }
                if let level = entry.level, !level.isEmpty {
                    prefix += " [\(level)]"
                }
                return "\(prefix) \(entry.message)"
            }
            .joined(separator: "\n")
    }

    private func internalAppend(_ entry: DebugLogEntry) {
        entries.append(entry)
        if entries.count > maxEntryCount {
            entries.removeFirst(entries.count - maxEntryCount)
        }
    }

    private func installStdCapture() {
        stdoutPipe = installPipeCapture(for: STDOUT_FILENO, originalFD: &stdoutOriginalFD, source: .stdout)
        stderrPipe = installPipeCapture(for: STDERR_FILENO, originalFD: &stderrOriginalFD, source: .stderr)

        setvbuf(stdout, nil, _IOLBF, 0)
        setvbuf(stderr, nil, _IONBF, 0)
    }

    private func installPipeCapture(for fd: Int32, originalFD: inout Int32, source: DebugLogEntry.Source) -> Pipe? {
        guard originalFD == -1 else { return nil }

        let pipe = Pipe()
        originalFD = dup(fd)
        guard originalFD != -1 else { return nil }

        let writeFD = pipe.fileHandleForWriting.fileDescriptor
        guard dup2(writeFD, fd) != -1 else {
            close(originalFD)
            originalFD = -1
            return nil
        }
        let capturedOriginalFD = originalFD

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            self?.forward(data, to: capturedOriginalFD)
            Task { @MainActor [weak self] in
                self?.consume(data, from: source)
            }
        }

        return pipe
    }

    nonisolated private func forward(_ data: Data, to fd: Int32?) {
        guard let fd, fd >= 0 else { return }

        data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return }

            var totalWritten = 0
            while totalWritten < rawBuffer.count {
                let written = write(fd, baseAddress.advanced(by: totalWritten), rawBuffer.count - totalWritten)
                if written <= 0 { break }
                totalWritten += written
            }
        }
    }

    private func consume(_ data: Data, from source: DebugLogEntry.Source) {
        let fragment = String(decoding: data, as: UTF8.self)

        switch source {
        case .stdout:
            stdoutBuffer += fragment
            drainBuffer(&stdoutBuffer, as: .stdout)
        case .stderr:
            stderrBuffer += fragment
            drainBuffer(&stderrBuffer, as: .stderr)
        case .oslog:
            break
        }
    }

    private func drainBuffer(_ buffer: inout String, as source: DebugLogEntry.Source) {
        let lines = buffer.split(separator: "\n", omittingEmptySubsequences: false)
        let hasTrailingNewline = buffer.hasSuffix("\n")
        let completedCount = hasTrailingNewline ? lines.count : max(lines.count - 1, 0)

        if completedCount > 0 {
            for index in 0..<completedCount {
                let rawLine = String(lines[index]).trimmingCharacters(in: .newlines)
                guard !rawLine.isEmpty else { continue }
                internalAppend(
                    DebugLogEntry(
                        date: .now,
                        source: source,
                        category: nil,
                        level: nil,
                        message: rawLine
                    )
                )
            }
        }

        buffer = hasTrailingNewline ? "" : String(lines.last ?? "")
    }

    nonisolated private static func osLogLevelName(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .undefined: return "undefined"
        case .debug: return "debug"
        case .info: return "info"
        case .notice: return "notice"
        case .error: return "error"
        case .fault: return "fault"
        @unknown default: return "unknown"
        }
    }
}

struct DebugLogViewerView: View {
    // 配合 @Observable，直接获取单例即可
    private let center = DebugLogCenter.shared

    var body: some View {
        List {
            if center.entries.isEmpty {
                Text("暂无日志")
                    .foregroundStyle(.secondary)
            } else {
                // 直接使用 .reversed()，避免 Array() 导致的巨量内存重新分配
                ForEach(center.entries.reversed()) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(header(for: entry))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(entry.message)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("日志查看器")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: center.exportText()) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
                Button {
                    center.refreshOSLogs()
                } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
            }
        }
        .task {
            center.start()
            while !Task.isCancelled {
                center.refreshOSLogs()
                try? await Task.sleep(for: .seconds(1.0))
            }
        }
    }

    private func header(for entry: DebugLogEntry) -> String {
        let time = entry.date.formatted(date: .omitted, time: .standard)
        var sections = ["[\(time)]", "[\(entry.source.rawValue)]"]
        if let category = entry.category, !category.isEmpty {
            sections.append("[\(category)]")
        }
        if let level = entry.level, !level.isEmpty {
            sections.append("[\(level)]")
        }
        return sections.joined(separator: " ")
    }
}
#endif
