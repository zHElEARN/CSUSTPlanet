//
//  ScoreRingPreviewData.swift
//  CSUSTPlanet
//
//  Created by Zhe_Learn on 2026/10/18.
//

enum ScoreRingPreviewData {
    /// 常规数据：三段 30 / 20 / 50
    static let normalSegments: [ScoreSegment] = [
        ScoreSegment(weight: 30, progress: 0.92),
        ScoreSegment(weight: 20, progress: 0.96),
        ScoreSegment(weight: 50, progress: 0.90),
    ]

    /// 含 5% 极小段
    static let tinySegments: [ScoreSegment] = [
        ScoreSegment(weight: 5, progress: 0.80),
        ScoreSegment(weight: 15, progress: 0.70),
        ScoreSegment(weight: 20, progress: 0.60),
        ScoreSegment(weight: 20, progress: 0.90),
        ScoreSegment(weight: 40, progress: 0.85),
    ]

    /// 极端 1 / 1 / 98
    static let extremeSegments: [ScoreSegment] = [
        ScoreSegment(weight: 1, progress: 0.50),
        ScoreSegment(weight: 1, progress: 0.50),
        ScoreSegment(weight: 98, progress: 0.90),
    ]

    /// 单段 100%
    static let singleSegment: [ScoreSegment] = [
        ScoreSegment(weight: 100, progress: 0.75)
    ]

    /// 满分
    static let fullScoreSegments: [ScoreSegment] = [
        ScoreSegment(weight: 50, progress: 1.0),
        ScoreSegment(weight: 50, progress: 1.0),
    ]

    /// 零分
    static let zeroScoreSegments: [ScoreSegment] = [
        ScoreSegment(weight: 50, progress: 0.0),
        ScoreSegment(weight: 50, progress: 0.6),
    ]

    /// 五段等分
    static let fiveEqualSegments: [ScoreSegment] = (1...5).map { index in
        ScoreSegment(weight: 20, progress: Double(index) / 5)
    }

    static let emptySegments: [ScoreSegment] = []
}
