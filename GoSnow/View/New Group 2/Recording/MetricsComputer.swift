//
//  MetricsComputer.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

import Foundation
import CoreLocation

public protocol MetricsComputer: AnyObject {
    func reset()
    func consume(_ loc: CLLocation)
    func tick1s()                // 每秒推进时长、平均值等
    func finalize() -> SkiSession
    var currentSpeedKmh: Double { get }
    var distanceKm: Double { get }
    var durationSec: Int { get }
    var topSpeedKmh: Double { get }
    var avgSpeedKmh: Double { get }
}

