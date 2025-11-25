//
//  SessionRecorder.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

import Foundation
import CoreLocation

public enum RecordingState { case idle, recording, paused }

public protocol SessionRecorder: AnyObject {
    var state: RecordingState { get }
    var currentSpeedKmh: Double { get }
    var distanceKm: Double { get }
    var durationSec: Int { get }

    /// 新增：最近一次有效定位（用于地图跟随）
    var lastCoordinate: CLLocationCoordinate2D? { get }

    func start(resortId: Int?) async
    func pause()
    func resume()
    func stop() async -> SkiSession
}


