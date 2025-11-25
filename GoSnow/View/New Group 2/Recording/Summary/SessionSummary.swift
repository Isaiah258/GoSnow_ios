//
//  SessionSummary.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

// Recording/UI/SessionSummary.swift
import Foundation

public struct SessionSummary: Identifiable, Sendable {
    public let id = UUID()
    public let distanceKm: Double
    public let avgSpeedKmh: Double
    public let topSpeedKmh: Double
    public let elevationDropM: Int?   // 先占位，后续填海拔逻辑
    public let durationSec: Int
}

public extension SessionSummary {
    var durationText: String {
        let h = durationSec / 3600
        let m = (durationSec % 3600) / 60
        let s = durationSec % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }
}

