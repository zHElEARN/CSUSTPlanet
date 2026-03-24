//
//  AppSandboxFileBrowserView.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/3/24.
//

#if DEBUG
import SwiftUI

struct AppSandboxFileBrowserView: View {
    private let sandboxRootURL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

    var body: some View {
        AppSandboxDirectoryView(
            directoryURL: sandboxRootURL,
            rootURL: sandboxRootURL
        )
        .navigationTitle("App沙箱文件")
    }
}

private struct AppSandboxDirectoryView: View {
    let directoryURL: URL
    let rootURL: URL

    @State private var entries: [AppSandboxFileEntry] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("当前位置") {
                Text(displayPath(for: directoryURL))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Section("目录内容") {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if entries.isEmpty {
                    Text("当前目录为空")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries) { entry in
                        if entry.isDirectory {
                            NavigationLink(
                                destination: AppSandboxDirectoryView(
                                    directoryURL: entry.url,
                                    rootURL: rootURL
                                )
                                .navigationTitle(entry.name)
                            ) {
                                AppSandboxEntryRow(entry: entry)
                            }
                        } else {
                            AppSandboxEntryRow(entry: entry)
                        }
                    }
                }
            }
        }
        .toolbar {
            Button(action: loadEntries) {
                Label("刷新", systemImage: "arrow.clockwise")
            }
        }
        .task(id: directoryURL.path) {
            loadEntries()
        }
    }

    private func loadEntries() {
        do {
            entries = try AppSandboxFileEntry.loadEntries(in: directoryURL)
            errorMessage = nil
        } catch {
            entries = []
            errorMessage = "读取失败：\(error.localizedDescription)"
        }
    }

    private func displayPath(for url: URL) -> String {
        guard url.path.hasPrefix(rootURL.path) else {
            return url.path
        }

        let relative = String(url.path.dropFirst(rootURL.path.count))
        return relative.isEmpty ? "/" : relative
    }
}

private struct AppSandboxEntryRow: View {
    let entry: AppSandboxFileEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundStyle(entry.isDirectory ? .blue : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .lineLimit(2)

                Text(entry.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct AppSandboxFileEntry: Identifiable {
    let url: URL
    let isDirectory: Bool
    let fileSize: Int?
    let modificationDate: Date?

    var id: String { url.path }

    var name: String {
        url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent
    }

    var detailText: String {
        let dateText = modificationDate.map(Self.dateFormatter.string(from:)) ?? "未知时间"
        if isDirectory {
            return "文件夹 · \(dateText)"
        }

        let sizeText =
            fileSize.map {
                ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file)
            } ?? "未知大小"
        return "\(sizeText) · \(dateText)"
    }

    static func loadEntries(in directoryURL: URL) throws -> [AppSandboxFileEntry] {
        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        let urls = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(keys),
            options: []
        )

        return
            urls
            .compactMap { url in
                guard let values = try? url.resourceValues(forKeys: keys) else {
                    return nil
                }

                return AppSandboxFileEntry(
                    url: url,
                    isDirectory: values.isDirectory ?? false,
                    fileSize: values.fileSize,
                    modificationDate: values.contentModificationDate
                )
            }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory && !rhs.isDirectory
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
#endif
