//
//  BasicMetricsComputer.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

// Recording/Domain/BasicMetricsComputer.swift
import Foundation
import CoreLocation

// 可调参数集中这里
struct MetricsConfig {
    // 过滤
    var maxHorizontalAccuracyM: CLLocationAccuracy = 30       // >30m 判为不可靠
    var maxSpeedKmh: Double = 120                              // >120km/h 视为异常
    var minDtSec: Double = 0.2                                 // 相邻点最小时间间隔
    // 平滑
    var medianWindow: Int = 5                                  // 中值窗口 3~5
    var lowPassAlpha: Double = 0.80                            // 低通 α 越大越“稳”
    // 一致性校验（速度 vs 距离/时间）
    var consistencyTolerance: Double = 0.35                    // 相对误差 >35% 视为不一致
    var clampOvershootRatio: Double = 1.5                      // 距离上限 = 速度*dt 的 1.5 倍
    // 距离累加阈值
    var minSpeedForDistanceKmh: Double = 0.8                   // 低于此速度不累计距离
}

final class BasicMetricsComputer: MetricsComputer {
    // MARK: - State
    private var cfg = MetricsConfig()

    private var sessionId = UUID()
    private var startAt = Date()
    private var endAt = Date()

    private var _durationSec = 0
    private var _distanceKm: Double = 0
    private var _topSpeedKmh: Double = 0

    private var lastLoc: CLLocation?
    private var lastSmoothSpeed: Double = 0
    private var speedWindow: [Double] = []

    // MARK: - Exposed
    var currentSpeedKmh: Double = 0
    var distanceKm: Double { _distanceKm }
    var durationSec: Int { _durationSec }
    var topSpeedKmh: Double { _topSpeedKmh }
    var avgSpeedKmh: Double {
        guard _durationSec > 0 else { return 0 }
        let hours = Double(_durationSec)/3600.0
        return hours > 0 ? (_distanceKm / hours) : 0
    }

    // MARK: - Lifecycle
    func reset() {
        sessionId = UUID()
        startAt = Date()
        endAt = startAt
        _durationSec = 0
        _distanceKm = 0
        _topSpeedKmh = 0
        lastLoc = nil
        lastSmoothSpeed = 0
        speedWindow.removeAll()
        currentSpeedKmh = 0
    }

    func tick1s() {
        _durationSec += 1
        endAt = Date()
    }

    // MARK: - Core
    func consume(_ loc: CLLocation) {
        endAt = Date()

        // 1) 基础过滤：精度/无效速度
        guard loc.horizontalAccuracy >= 0,
              loc.horizontalAccuracy <= cfg.maxHorizontalAccuracyM
        else { return }

        // dt
        var dt = 0.0
        if let last = lastLoc {
            dt = loc.timestamp.timeIntervalSince(last.timestamp)
            if dt < cfg.minDtSec { return } // 采样太密，忽略
        }

        // 2) 原始速度（m/s -> km/h），不可信时为 nil
        let rawSpeedKmh: Double? = {
            let v = loc.speed
            if v.isNaN || v.isInfinite || v < 0 { return nil }
            let kmh = v * 3.6
            if kmh > cfg.maxSpeedKmh { return nil }
            return kmh
        }()

        // 3) 距离与基于距离的速度估计
        var deltaKm = 0.0
        var vDeltaKmh: Double? = nil
        if let last = lastLoc {
            deltaKm = haversineKm(from: last.coordinate, to: loc.coordinate)
            if dt > 0 {
                vDeltaKmh = (deltaKm / (dt / 3600.0)) // km / h
            }
        }

        // 4) 挑选一个“观测速度”用于平滑：优先用 GPS 提供的 speed，其次用 vDelta
        let observedSpeedKmh: Double = {
            if let v = rawSpeedKmh { return v }
            return max(0, vDeltaKmh ?? 0)
        }()

        // 5) 一致性校验：rawSpeed 与 vDelta 差异过大且本点精度一般 -> 保守处理
        var distanceToAccumulateKm = deltaKm
        if let vRaw = rawSpeedKmh, let vDelta = vDeltaKmh, vDelta > 0 {
            let relDiff = abs(vRaw - vDelta) / vDelta
            if relDiff > cfg.consistencyTolerance {
                // 不一致：用较小速度估计上限，且钳制距离，或直接减权/忽略
                let trusted = min(vRaw, vDelta)
                let maxAllowedKm = (trusted / 3600.0) * dt * cfg.clampOvershootRatio
                distanceToAccumulateKm = min(deltaKm, maxAllowedKm)
            }
        }

        // 6) 速度平滑：中值 + 低通
        let median = pushAndMedian(observedSpeedKmh)
        let smooth = lowPass(prev: lastSmoothSpeed, current: median, alpha: cfg.lowPassAlpha)
        lastSmoothSpeed = smooth
        currentSpeedKmh = smooth

        // 7) 最高速基于平滑曲线
        _topSpeedKmh = max(_topSpeedKmh, smooth)

        // 8) 距离累计：速度很低时不累加，避免 GPS 抖动导致“原地走路”
        if smooth >= cfg.minSpeedForDistanceKmh, dt > 0 {
            // 再做一次越界保护：基于平滑速度的上限
            let maxBySmoothKm = (smooth / 3600.0) * dt * cfg.clampOvershootRatio
            _distanceKm += min(distanceToAccumulateKm, maxBySmoothKm)
        }

        lastLoc = loc
    }

    func finalize() -> SkiSession {
        return SkiSession(
            id: sessionId,
            startAt: startAt,
            endAt: endAt,
            durationSec: _durationSec,
            distanceKm: _distanceKm,
            topSpeedKmh: _topSpeedKmh,
            avgSpeedKmh: avgSpeedKmh
        )
    }

    // MARK: - Helpers

    private func pushAndMedian(_ v: Double) -> Double {
        // 固定窗口长度
        let w = max(3, cfg.medianWindow | 1) // 确保为奇数窗口
        speedWindow.append(v)
        if speedWindow.count > w { speedWindow.removeFirst(speedWindow.count - w) }
        let sorted = speedWindow.sorted()
        return sorted[sorted.count / 2]
    }

    private func lowPass(prev: Double, current: Double, alpha: Double) -> Double {
        return alpha * prev + (1 - alpha) * current
    }

    private func haversineKm(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let R = 6371.0 // km
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2)
              + cos(from.latitude * .pi / 180) * cos(to.latitude * .pi / 180)
              * sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

