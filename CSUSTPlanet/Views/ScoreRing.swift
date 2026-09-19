//
//  ScoreRing.swift
//  CSUSTPlanet
//
//  Created by DeepSeek on 2026/9/16.
//

import SwiftUI

// MARK: - 数据模型

/// 权重环上的一段。
///
/// `weight` 与 `progress` 是两个互相独立的维度：前者决定弧长，后者决定厚度。
struct ScoreSegment: Hashable {
    /// 弧长权重，≤ 0 的段不参与绘制
    var weight: Double
    /// 得分率（0...1）
    var progress: Double

    init(weight: Double, progress: Double) {
        self.weight = max(weight, 0)
        self.progress = min(max(progress, 0), 1)
    }
}

// MARK: - 设计常量

/// 环的几何与视觉常量，整体设计参考 Apple 健康里的评分环。
///
/// 所有几何都以 `baseDiameter` 为基准按比例定义，因此外部只需要决定一个尺寸。
private enum ScoreRingDesign {
    /// 设计基准直径
    static let baseDiameter: CGFloat = 112
    /// 环宽与直径之比
    static let thicknessRatio: CGFloat = 2.0 / 9.0
    /// 相邻两段之间的缺口（度），存在极小段时会收缩，见 `gap(minimumShare:)`
    static let maximumGap: Double = 3.9
    /// 第一段起点：-90° 为 12 点方向，顺时针为正
    static let startAngle: Double = -90
    /// 浅色层不透明度
    static let paleOpacity: Double = 0.30
    /// 端头圆角与环宽之比
    static let cornerRatio: CGFloat = 0.31
    /// 实心层外角圆角与其厚度之比
    static let solidOuterCornerRatio: CGFloat = 0.36
    /// 圆角下限，避免低分段的端头变成尖角
    static let minimumCornerRadius: CGFloat = 2
    /// 环心分数字号与直径之比
    static let scoreFontRatio: CGFloat = 28 / 112
}

// MARK: - 几何计算

/// 按外部给定的边长推导出的全部尺寸
private struct ScoreRingGeometry {
    let side: CGFloat

    var scale: CGFloat { side / ScoreRingDesign.baseDiameter }
    var outerRadius: CGFloat { side / 2 }
    var thickness: CGFloat { side * ScoreRingDesign.thicknessRatio }
    var innerRadius: CGFloat { outerRadius - thickness }
    var cornerRadius: CGFloat {
        max(thickness * ScoreRingDesign.cornerRatio, ScoreRingDesign.minimumCornerRadius * scale)
    }

    var scoreFontSize: CGFloat { side * ScoreRingDesign.scoreFontRatio }

    /// 端头圆角的最大可用半径。
    ///
    /// 圆角与径向端边相切会占用一定的角向偏移：内角 `asin(ρ / (r内 + ρ))`、
    /// 外角 `asin(ρ / (r外 − ρ))`。两者之和一旦超过该段跨度，`Path.addArc` 的起点就会越过终点、
    /// 反向绕远路，把整个环涂满这一段的颜色（占比约 6% 以下的小段会触发），所以必须按跨度夹紧。
    /// 该函数对 ρ 单调递增，用二分求最大值。
    static func maximumCornerRadius(span: Double, innerRadius: CGFloat, outerRadius: CGFloat) -> CGFloat {
        guard span > 0, outerRadius > innerRadius else { return 0 }
        let maximum = (outerRadius - innerRadius) / 2
        let budget = span * 0.85

        func angularOffset(_ radius: CGFloat) -> Double {
            guard radius > 0 else { return 0 }
            let inner = asin(min(1, radius / (innerRadius + radius))) * 180 / .pi
            let outer = asin(min(1, radius / max(outerRadius - radius, 0.0001))) * 180 / .pi
            return inner + outer
        }

        guard angularOffset(maximum) > budget else { return maximum }

        var low: CGFloat = 0
        var high = maximum
        for _ in 0..<24 {
            let middle = (low + high) / 2
            if angularOffset(middle) <= budget {
                low = middle
            } else {
                high = middle
            }
        }
        return low
    }

    /// 缺口：正常情况下就是设计值，只有存在极小段时才收缩，
    /// 保证每段的可见跨度都大于 0，否则该段的圆弧会反向绕远路。
    func gap(minimumShare: Double) -> Double {
        min(ScoreRingDesign.maximumGap, minimumShare * 0.4)
    }

    func arcs(for segments: [ScoreSegment]) -> [ScoreRingArc] {
        guard side > 0, innerRadius > 0 else { return [] }

        let visibleSegments = segments.filter { $0.weight > 0 }
        let totalWeight = visibleSegments.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return [] }

        // 只有一个可见段时占满整圈，走无缝圆环路径，不留缺口
        let isFullCircle = visibleSegments.count == 1
        let minimumShare = 360 * (visibleSegments.map(\.weight).min() ?? 0) / totalWeight
        let gap = isFullCircle ? 0 : gap(minimumShare: minimumShare)

        var cursor = ScoreRingDesign.startAngle

        return visibleSegments.enumerated().map { index, segment in
            let share = 360 * segment.weight / totalWeight
            let start = cursor + gap / 2
            let end = cursor + share - gap / 2
            cursor += share

            let span = end - start
            let solidThickness = thickness * segment.progress
            let solidOuterRadius = innerRadius + solidThickness

            // 两层共用内缘与端边，圆角取两者中更严格的上限，实心层外缘才会正好落在两层的分界线上
            let fullRingLimit = Self.maximumCornerRadius(
                span: span, innerRadius: innerRadius, outerRadius: outerRadius
            )
            // 得分为 0 时没有实心层，不参与约束
            let cornerLimit =
                solidThickness > 0
                ? min(
                    fullRingLimit,
                    Self.maximumCornerRadius(
                        span: span, innerRadius: innerRadius, outerRadius: solidOuterRadius
                    )
                )
                : fullRingLimit

            let innerCorner = min(cornerRadius, cornerLimit)
            let paleOuterCorner = min(cornerRadius, fullRingLimit)
            let solidOuterCorner = min(
                max(solidThickness * ScoreRingDesign.solidOuterCornerRatio, ScoreRingDesign.minimumCornerRadius * scale),
                cornerLimit
            )

            return ScoreRingArc(
                color: ScoreRing.color(at: index),
                startAngle: start,
                endAngle: end,
                innerRadius: innerRadius,
                outerRadius: outerRadius,
                solidOuterRadius: solidOuterRadius,
                innerCornerRadius: innerCorner,
                outerCornerRadius: paleOuterCorner,
                solidOuterCornerRadius: solidOuterCorner,
                isFullCircle: isFullCircle
            )
        }
    }
}

/// 一段环的绘制参数（已按实际尺寸换算完毕）
private struct ScoreRingArc {
    let color: Color
    let startAngle: Double
    let endAngle: Double
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let solidOuterRadius: CGFloat
    /// 浅色层与实心层共用的内角圆角，两层端边因此严丝合缝
    let innerCornerRadius: CGFloat
    let outerCornerRadius: CGFloat
    let solidOuterCornerRadius: CGFloat
    /// 单段占满整圈，走无缝圆环路径
    let isFullCircle: Bool
}

// MARK: - 环形扇区

/// 环形扇区：内外两条同心圆弧 + 两端「径向直边」，内外角可分别指定圆角半径。
///
/// 端头是「直边 + 圆角」而不是 `stroke(lineCap: .round)` 的半圆头，
/// 这是 Apple 健康那种端头的关键特征。
private struct RingSectorShape: Shape {
    /// 起始端边角度（度，-90° = 12 点方向，顺时针为正）
    var startAngle: Double
    var endAngle: Double
    var innerRadius: CGFloat
    var outerRadius: CGFloat
    var innerCornerRadius: CGFloat
    var outerCornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        // 跨度非正直接不画：`addArc` 起点越过终点会反向绕远路，把整环涂成该色
        guard endAngle > startAngle, outerRadius > innerRadius else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r1 = min(innerRadius, outerRadius)
        let r2 = max(innerRadius, outerRadius)
        let maxCorner = (r2 - r1) / 2
        let ri = min(max(innerCornerRadius, 0), maxCorner)
        let ro = min(max(outerCornerRadius, 0), maxCorner)

        func point(_ degree: Double, _ radius: CGFloat) -> CGPoint {
            let angle = degree * .pi / 180
            return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        }

        // 圆角圆心的角向偏移：与径向直边相切 ⇒ sin(δ) = ρ / r
        // 圆角圆心在扇区「内侧」：起端 +δ、末端 −δ
        var di = ri > 0 ? asin(min(1, ri / (r1 + ri))) * 180 / .pi : 0
        var dOut = ro > 0 ? asin(min(1, ro / (r2 - ro))) * 180 / .pi : 0

        // 兜底：端头圆角的角向偏移之和不得超过跨度（正常情况由调用方夹紧）
        let budget = (endAngle - startAngle) * 0.9
        if di + dOut > budget, di + dOut > 0 {
            let ratio = budget / (di + dOut)
            di *= ratio
            dOut *= ratio
        }

        var path = Path()
        // 起端内角 → 内弧 → 末端内角 → 端边 → 末端外角 → 外弧 → 起端外角
        path.move(to: point(startAngle, (r1 + ri) * cos(di * .pi / 180)))
        addCorner(
            &path, center: point(startAngle + di, r1 + ri), radius: ri,
            to: point(startAngle + di, r1))
        path.addArc(
            center: center, radius: r1,
            startAngle: .degrees(startAngle + di), endAngle: .degrees(endAngle - di),
            clockwise: false)
        addCorner(
            &path, center: point(endAngle - di, r1 + ri), radius: ri,
            to: point(endAngle, (r1 + ri) * cos(di * .pi / 180)))
        path.addLine(to: point(endAngle, (r2 - ro) * cos(dOut * .pi / 180)))
        addCorner(
            &path, center: point(endAngle - dOut, r2 - ro), radius: ro,
            to: point(endAngle - dOut, r2))
        path.addArc(
            center: center, radius: r2,
            startAngle: .degrees(endAngle - dOut), endAngle: .degrees(startAngle + dOut),
            clockwise: true)
        addCorner(
            &path, center: point(startAngle + dOut, r2 - ro), radius: ro,
            to: point(startAngle, (r2 - ro) * cos(dOut * .pi / 180)))
        path.closeSubpath()
        return path
    }

    private func addCorner(_ path: inout Path, center: CGPoint, radius: CGFloat, to end: CGPoint) {
        guard radius > 0.01, let start = path.currentPoint else {
            path.addLine(to: end)
            return
        }
        let startAngle = atan2(start.y - center.y, start.x - center.x)
        let endAngle = atan2(end.y - center.y, end.x - center.x)
        var delta = endAngle - startAngle
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        path.addArc(
            center: center, radius: radius,
            startAngle: .radians(startAngle), endAngle: .radians(startAngle + delta),
            clockwise: delta < 0)
    }
}

// MARK: - 无缝圆环

/// 无缝圆环：内外两个同心圆，用 even-odd 填充挖空内圈。
private struct RingAnnulusShape: Shape {
    var innerRadius: CGFloat
    var outerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        guard outerRadius > innerRadius, innerRadius > 0 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addEllipse(
            in: CGRect(
                x: center.x - outerRadius, y: center.y - outerRadius,
                width: outerRadius * 2, height: outerRadius * 2
            ))
        path.addEllipse(
            in: CGRect(
                x: center.x - innerRadius, y: center.y - innerRadius,
                width: innerRadius * 2, height: innerRadius * 2
            ))
        return path
    }
}

// MARK: - 权重环

/// 权重环：弧长表达权重，厚度表达得分率。
///
/// 全部几何都以 112pt 为基准等比缩放，尺寸完全由外部 frame 决定，调整大小只需要改外部那一个数字。
/// 环心默认留空，需要放总分时传入 `score`：
///
/// ```swift
/// ScoreRing(segments: [
///     ScoreSegment(weight: 30, progress: 0.92),
///     ScoreSegment(weight: 20, progress: 0.96),
///     ScoreSegment(weight: 50, progress: 0.90),
/// ])
/// .frame(width: 140, height: 140)
/// ```
///
/// 边界行为：
/// - 只有一个可见段时画无缝整圆，不留缺口；
/// - 占比过小的段会自动收缩缺口与端头圆角，保证任何数据都能画对；
/// - `segments` 为空或总权重为 0 时只保留占位，不画环。
struct ScoreRing: View {
    var segments: [ScoreSegment]
    var score: Int? = nil

    /// 第 index 段使用的颜色，外部画图例/圆点时用它保持一致
    static func color(at index: Int) -> Color {
        ColorUtil.courseColors[index % ColorUtil.courseColors.count]
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let geometry = ScoreRingGeometry(side: side)

            ZStack {
                ForEach(Array(geometry.arcs(for: segments).enumerated()), id: \.offset) { _, arc in
                    ZStack {
                        paleLayer(arc)
                        solidLayer(arc)
                    }
                }

                if let score {
                    Text("\(score)")
                        .font(.system(size: geometry.scoreFontSize, weight: .bold))
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: 图层

    /// 浅色层：整环宽的圆角扇区，代表该段「没拿到」的厚度
    @ViewBuilder
    private func paleLayer(_ arc: ScoreRingArc) -> some View {
        if arc.isFullCircle {
            RingAnnulusShape(innerRadius: arc.innerRadius, outerRadius: arc.outerRadius)
                .fill(arc.color.opacity(ScoreRingDesign.paleOpacity), style: FillStyle(eoFill: true))
        } else {
            RingSectorShape(
                startAngle: arc.startAngle,
                endAngle: arc.endAngle,
                innerRadius: arc.innerRadius,
                outerRadius: arc.outerRadius,
                innerCornerRadius: arc.innerCornerRadius,
                outerCornerRadius: arc.outerCornerRadius
            )
            .fill(arc.color.opacity(ScoreRingDesign.paleOpacity))
        }
    }

    /// 实心层：按得分率自内缘向外生长，叠在浅色层上并共用内缘与端边
    @ViewBuilder
    private func solidLayer(_ arc: ScoreRingArc) -> some View {
        if arc.solidOuterRadius > arc.innerRadius {
            if arc.isFullCircle {
                RingAnnulusShape(innerRadius: arc.innerRadius, outerRadius: arc.solidOuterRadius)
                    .fill(arc.color, style: FillStyle(eoFill: true))
            } else {
                RingSectorShape(
                    startAngle: arc.startAngle,
                    endAngle: arc.endAngle,
                    innerRadius: arc.innerRadius,
                    outerRadius: arc.solidOuterRadius,
                    innerCornerRadius: arc.innerCornerRadius,
                    outerCornerRadius: arc.solidOuterCornerRadius
                )
                .fill(arc.color)
            }
        }
    }
}

// MARK: - Preview

private struct ScoreRingPreviewItem: View {
    var caption: String
    var segments: [ScoreSegment]
    var score: Int
    var side: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
            ScoreRing(segments: segments, score: score)
                .frame(width: side, height: side)
        }
    }
}

/// 常规数据：三段 30 / 20 / 50
private let scoreRingPreviewNormal: [ScoreSegment] = [
    ScoreSegment(weight: 30, progress: 0.92),
    ScoreSegment(weight: 20, progress: 0.96),
    ScoreSegment(weight: 50, progress: 0.90),
]

#Preview("1 · 常规三段 30/20/50") {
    ScoreRingPreviewItem(caption: "108° / 72° / 180°，厚度 = 得分率", segments: scoreRingPreviewNormal, score: 93)
        .padding()
}

#Preview("2 · 含 5% 极小段") {
    ScoreRingPreviewItem(
        caption: "5% 段：缺口与端头圆角自动收紧",
        segments: [
            ScoreSegment(weight: 5, progress: 0.80),
            ScoreSegment(weight: 15, progress: 0.70),
            ScoreSegment(weight: 20, progress: 0.60),
            ScoreSegment(weight: 20, progress: 0.90),
            ScoreSegment(weight: 40, progress: 0.85),
        ],
        score: 78
    )
    .padding()
}

#Preview("3 · 极端 1/1/98") {
    ScoreRingPreviewItem(
        caption: "1% 段：缺口收缩到 1.44°",
        segments: [
            ScoreSegment(weight: 1, progress: 0.50),
            ScoreSegment(weight: 1, progress: 0.50),
            ScoreSegment(weight: 98, progress: 0.90),
        ],
        score: 89
    )
    .padding()
}

#Preview("4 · 单段 100%（无缝整圆）") {
    ScoreRingPreviewItem(
        caption: "只有一个组成项：整圆无缺口",
        segments: [ScoreSegment(weight: 100, progress: 0.75)],
        score: 75
    )
    .padding()
}

#Preview("5 · 满分与零分") {
    HStack(alignment: .bottom, spacing: 24) {
        ScoreRingPreviewItem(
            caption: "满分：全实心",
            segments: [ScoreSegment(weight: 50, progress: 1.0), ScoreSegment(weight: 50, progress: 1.0)],
            score: 100
        )
        ScoreRingPreviewItem(
            caption: "零分：只有浅色层",
            segments: [ScoreSegment(weight: 50, progress: 0.0), ScoreSegment(weight: 50, progress: 0.6)],
            score: 30
        )
    }
    .padding()
}

#Preview("6 · 五段等分 20%×5") {
    ScoreRingPreviewItem(
        caption: "五段等分，每段 72°",
        segments: (1...5).map { ScoreSegment(weight: 20, progress: Double($0) / 5) },
        score: 60
    )
    .padding()
}

#Preview("7 · 尺寸 80 / 120 / 180") {
    HStack(alignment: .bottom, spacing: 20) {
        ScoreRingPreviewItem(caption: "80", segments: scoreRingPreviewNormal, score: 93, side: 80)
        ScoreRingPreviewItem(caption: "120", segments: scoreRingPreviewNormal, score: 93, side: 120)
        ScoreRingPreviewItem(caption: "180", segments: scoreRingPreviewNormal, score: 93, side: 180)
    }
    .padding()
}

#Preview("8 · 空数据") {
    ScoreRingPreviewItem(caption: "空数组：不画环，只保留占位", segments: [], score: 0)
        .padding()
}

#Preview("9 · 深色模式") {
    ScoreRingPreviewItem(caption: "浅色层在深色模式下是暗色调，语义不变", segments: scoreRingPreviewNormal, score: 93)
        .padding()
        .preferredColorScheme(.dark)
}

#Preview("10 · 环心留空") {
    VStack(alignment: .leading, spacing: 8) {
        Text("不传 score 时环心为空")
            .font(.caption)
            .foregroundStyle(.secondary)
        ScoreRing(segments: scoreRingPreviewNormal)
            .frame(width: 140, height: 140)
    }
    .padding()
}
