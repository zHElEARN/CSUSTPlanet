//
//  LicensePlistLoader.swift
//  CSUSTPlanet
//
//  Created by Codex on 2026/4/3.
//

import Foundation

struct OpenSourceLicense: Identifiable, Hashable {
    let id: String
    let title: String
    let licenseName: String?
    let body: String?
    let errorMessage: String?

    var subtitle: String? {
        if let errorMessage {
            return errorMessage
        }

        guard let licenseName, licenseName.isKnownLicenseName else {
            return nil
        }

        return licenseName
    }
}

enum LicensePlistLoader {
    static func loadLicenses(from bundle: Bundle = .main) throws -> [OpenSourceLicense] {
        let rootURL = try locateRootPlist(in: bundle)
        let licenseDirectoryURL = rootURL.deletingLastPathComponent()
        let rootPlist = try readPropertyList(at: rootURL)
        let specifiers = try extractSpecifiers(from: rootPlist, fileName: rootURL.lastPathComponent)

        return specifiers.compactMap { specifier in
            guard specifier.type == "PSChildPaneSpecifier" else {
                return nil
            }

            return loadLicense(
                for: specifier,
                in: bundle,
                licenseDirectoryURL: licenseDirectoryURL
            )
        }
    }

    private static func loadLicense(
        for specifier: LicenseSpecifier,
        in bundle: Bundle,
        licenseDirectoryURL: URL
    ) -> OpenSourceLicense {
        do {
            let licenseURL = try locateLicensePlist(
                for: specifier.filePath,
                in: bundle,
                licenseDirectoryURL: licenseDirectoryURL
            )
            let plist = try readPropertyList(at: licenseURL)
            let childSpecifiers = try extractSpecifiers(from: plist, fileName: licenseURL.lastPathComponent)

            let bodyParts =
                childSpecifiers
                .compactMap { $0.footerText.trimmedNilIfEmpty }
            let body = bodyParts.isEmpty ? nil : bodyParts.joined(separator: "\n\n")

            let licenseName =
                childSpecifiers
                .compactMap { $0.licenseName.trimmedNilIfEmpty }
                .first(where: \.isKnownLicenseName)
                ?? childSpecifiers
                .compactMap { $0.licenseName.trimmedNilIfEmpty }
                .first

            return OpenSourceLicense(
                id: specifier.filePath,
                title: specifier.title,
                licenseName: licenseName,
                body: body,
                errorMessage: body == nil ? "未找到许可证正文" : nil
            )
        } catch {
            return OpenSourceLicense(
                id: specifier.filePath,
                title: specifier.title,
                licenseName: nil,
                body: nil,
                errorMessage: error.localizedDescription
            )
        }
    }

    private static func locateRootPlist(in bundle: Bundle) throws -> URL {
        let resourceRootURL = bundle.resourceURL ?? bundle.bundleURL

        let candidates = [
            bundle.url(
                forResource: "com.mono0926.LicensePlist",
                withExtension: "plist",
                subdirectory: "com.mono0926.LicensePlist.Output"
            ),
            resourceRootURL
                .appendingPathComponent("com.mono0926.LicensePlist.Output", isDirectory: true)
                .appendingPathComponent("com.mono0926.LicensePlist.plist"),
        ]

        if let url = candidates.compactMap(\.self).first(where: fileExists(at:)) {
            return url
        }

        throw LicensePlistLoaderError.missingRootPlist
    }

    private static func locateLicensePlist(
        for filePath: String,
        in bundle: Bundle,
        licenseDirectoryURL: URL
    ) throws -> URL {
        let normalizedPath = filePath.hasSuffix(".plist") ? filePath : "\(filePath).plist"
        let fileName = URL(fileURLWithPath: normalizedPath).lastPathComponent
        let baseName = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent

        let subdirectory = URL(fileURLWithPath: normalizedPath).deletingLastPathComponent().path
        let trimmedSubdirectory = subdirectory == "/" ? nil : subdirectory
        let bundleSubdirectory =
            if let trimmedSubdirectory {
                "com.mono0926.LicensePlist.Output/\(trimmedSubdirectory)"
            } else {
                "com.mono0926.LicensePlist.Output"
            }
        let resourceRootURL = bundle.resourceURL ?? bundle.bundleURL

        let candidates = [
            bundle.url(
                forResource: baseName,
                withExtension: "plist",
                subdirectory: bundleSubdirectory
            ),
            bundle.url(
                forResource: baseName,
                withExtension: "plist"
            ),
            licenseDirectoryURL
                .appendingPathComponent(normalizedPath),
            licenseDirectoryURL
                .appendingPathComponent(fileName),
            resourceRootURL
                .appendingPathComponent("com.mono0926.LicensePlist.Output", isDirectory: true)
                .appendingPathComponent(normalizedPath),
            resourceRootURL
                .appendingPathComponent(fileName),
        ]

        if let url = candidates.compactMap(\.self).first(where: fileExists(at:)) {
            return url
        }

        throw LicensePlistLoaderError.missingLicensePlist(path: normalizedPath)
    }

    private static func readPropertyList(at url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)

        guard let dictionary = plist as? [String: Any] else {
            throw LicensePlistLoaderError.invalidFormat(fileName: url.lastPathComponent)
        }

        return dictionary
    }

    private static func extractSpecifiers(from dictionary: [String: Any], fileName: String) throws -> [LicenseSpecifier] {
        guard let rawSpecifiers = dictionary["PreferenceSpecifiers"] as? [[String: Any]] else {
            throw LicensePlistLoaderError.invalidFormat(fileName: fileName)
        }

        return rawSpecifiers.map(LicenseSpecifier.init)
    }

    private static func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

private struct LicenseSpecifier {
    let type: String?
    let title: String
    let filePath: String
    let footerText: String?
    let licenseName: String?

    init(_ dictionary: [String: Any]) {
        type = dictionary["Type"] as? String
        title = dictionary["Title"] as? String ?? "未知项目"
        filePath = dictionary["File"] as? String ?? UUID().uuidString
        footerText = dictionary["FooterText"] as? String
        licenseName = dictionary["License"] as? String
    }
}

private enum LicensePlistLoaderError: LocalizedError {
    case missingRootPlist
    case missingLicensePlist(path: String)
    case invalidFormat(fileName: String)

    var errorDescription: String? {
        switch self {
        case .missingRootPlist:
            return "未找到 LicensePlist 目录。"
        case .missingLicensePlist(let path):
            return "未找到许可证文件：\(path)"
        case .invalidFormat(let fileName):
            return "plist 格式无效：\(fileName)"
        }
    }
}

extension Optional where Wrapped == String {
    fileprivate var trimmedNilIfEmpty: String? {
        guard let self else {
            return nil
        }

        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : self
    }
}

extension String {
    var isKnownLicenseName: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.caseInsensitiveCompare("unknown") != .orderedSame
    }
}
