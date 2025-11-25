//
//  SkiSession.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

import Foundation

public struct SkiSession: Identifiable, Codable, Equatable {
    public let id: UUID
    public let startAt: Date
    public var endAt: Date
    public var durationSec: Int
    public var distanceKm: Double
    public var topSpeedKmh: Double
    public var avgSpeedKmh: Double
    public var resortId: Int?

    public init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        durationSec: Int = 0,
        distanceKm: Double = 0,
        topSpeedKmh: Double = 0,
        avgSpeedKmh: Double = 0,
        resortId: Int? = nil
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.durationSec = durationSec
        self.distanceKm = distanceKm
        self.topSpeedKmh = topSpeedKmh
        self.avgSpeedKmh = avgSpeedKmh
        self.resortId = resortId
    }
}

