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
/// 视图表示协议
typealias PlatformViewRepresentable = NSViewRepresentable

#elseif os(iOS) || os(tvOS) || os(visionOS)
import UIKit

/// 颜色类
typealias PlatformColor = UIColor
/// 视图表示协议
typealias PlatformViewRepresentable = UIViewRepresentable

#endif
