//
//  PlatformAliases.swift
//  CSUSTPlanet
//
//  Created by Zachary Liu on 2026/3/15.
//

import Foundation
import SwiftUI

#if os(macOS)
import AppKit

/// 颜色类
typealias PlatformColor = NSColor
/// 图像类
typealias PlatformImage = NSImage
/// 字体类
typealias PlatformFont = NSFont
/// 贝塞尔路径
typealias PlatformBezierPath = NSBezierPath
/// 应用程序对象
typealias PlatformApplication = NSApplication
/// 屏幕对象
typealias PlatformScreen = NSScreen
/// 事件对象
typealias PlatformEvent = NSEvent
/// 剪贴板
typealias PlatformPasteboard = NSPasteboard

#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit

/// 颜色类
typealias PlatformColor = UIColor
/// 图像类
typealias PlatformImage = UIImage
/// 字体类
typealias PlatformFont = UIFont
/// 贝塞尔路径
typealias PlatformBezierPath = UIBezierPath
/// 应用程序对象
typealias PlatformApplication = UIApplication
/// 屏幕对象
typealias PlatformScreen = UIScreen
/// 事件对象
typealias PlatformEvent = UIEvent
/// 剪贴板
typealias PlatformPasteboard = UIPasteboard

#endif
