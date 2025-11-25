//
//  BasicSessionRecorder.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

// Recording/Domain/BasicSessionRecorder.swift
import Foundation
import CoreLocation

// 自适应采样参数
struct AdaptiveConfig {
    var lowSpeedKmh: Double = 2.5
    var resumeSpeedKmh: Double = 4.0
    var lowSpeedDwellSec: TimeInterval = 30
    var warmupIgnoreSec: TimeInterval = 5
    var minSwitchIntervalSec: TimeInterval = 10
}

// 首定位防抖
struct WarmupConfig {
    var accuracyThresholdM: CLLocationAccuracy = 25
    var minGoodSamples: Int = 3
    var maxWarmupSec: TimeInterval = 10
}

final class BasicSessionRecorder: SessionRecorder {
    private var routePoints: [CLLocation] = []
    private let location: LocationService
    private let metrics: MetricsComputer
    private var ticker: Task<Void, Never>?

    private(set) var state: RecordingState = .idle

    private var cfg = AdaptiveConfig()
    private var warm = WarmupConfig()

    private var sessionStartTime: Date?
    private var lastSwitchTime: Date?
    private var lowSpeedStartTime: Date?
    private var currentSamplingMode: SamplingMode = .active

    private var isWarmingUp = false
    private var goodSampleCount = 0

    /// 新增：最近一次有效定位
    private(set) var lastCoordinate: CLLocationCoordinate2D?

    init(location: LocationService, metrics: MetricsComputer) {
        self.location = location
        self.metrics = metrics
        self.location.onSample = { [weak self] loc in
            self?.handleIncomingSample(loc)
        }
    }

    var currentSpeedKmh: Double { metrics.currentSpeedKmh }
    var distanceKm: Double { metrics.distance }
    var durationSec: Int { metrics.duration }

    // 兼容旧命名（如果你还在用）
    // 建议把 MetricsComputer 里公开属性名规范为 distance / duration
    public protocol SessionRecorderCoordinates: SessionRecorder {
        var lastCoordinate: CLLocationCoordinate2D? { get }
    }
    

}


public protocol SessionRecorderCoordinates: SessionRecorder {
    var lastCoordinate: CLLocationCoordinate2D? { get }
}

extension BasicSessionRecorder: SessionRecorderCoordinates {}

private extension MetricsComputer {
    var distance: Double { self.distanceKm }
    var duration: Int { self.durationSec }
}

extension BasicSessionRecorder {
    // MARK: Session APIs
    func start(resortId: Int?) async {
        guard state == .idle else { return }
        metrics.reset()
        sessionStartTime = Date()
        lastSwitchTime = sessionStartTime
        lowSpeedStartTime = nil

        isWarmingUp = true
        goodSampleCount = 0
        lastCoordinate = nil
        routePoints.removeAll()

        await location.start()
        location.setSamplingMode(.active)
        currentSamplingMode = .active

        startTick()
        state = .recording
    }

    func pause() {
        guard state == .recording else { return }
        stopTick()
        location.setSamplingMode(.idle)
        currentSamplingMode = .idle
        lastSwitchTime = Date()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        startTick()
        location.setSamplingMode(.active)
        currentSamplingMode = .active
        lastSwitchTime = Date()
        state = .recording
    }

    @MainActor
    func stop() async -> SkiSession {
        stopTick()
        location.setSamplingMode(.idle)
        location.stop()

        if let cls = location as? CoreLocationService {
            cls.onSample = nil
        }

        state = .idle
        isWarmingUp = false
        goodSampleCount = 0
        lowSpeedStartTime = nil

        return metrics.finalize()
    }

    // MARK: Internal ticking (1s)
    private func startTick() {
        stopTick()
        ticker = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await MainActor.run { self.metrics.tick1s() }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func stopTick() {
        ticker?.cancel()
        ticker = nil
    }

    // MARK: Sample pipeline
    private func handleIncomingSample(_ loc: CLLocation) {
        // 首定位防抖
        if isWarmingUp {
            let good = (loc.horizontalAccuracy >= 0 &&
                        loc.horizontalAccuracy <= warm.accuracyThresholdM)
            if good { goodSampleCount += 1 } else { goodSampleCount = 0 }
            let warmupElapsed = Date().timeIntervalSince(sessionStartTime ?? Date())
            if goodSampleCount >= warm.minGoodSamples || warmupElapsed >= warm.maxWarmupSec {
                isWarmingUp = false
                goodSampleCount = 0
            } else {
                return
            }
        }

        // 有效样本进入指标管道
        metrics.consume(loc)
        routePoints.append(loc)
        lastCoordinate = loc.coordinate

        evaluateAdaptiveSampling()
    }

    // MARK: Adaptive sampling
    private func evaluateAdaptiveSampling() {
        guard state == .recording else { return }

        let now = Date()

        if let start = sessionStartTime, now.timeIntervalSince(start) < cfg.warmupIgnoreSec {
            lowSpeedStartTime = nil
            return
        }
        if let last = lastSwitchTime, now.timeIntervalSince(last) < cfg.minSwitchIntervalSec {
            return
        }

        let v = metrics.currentSpeedKmh
        switch currentSamplingMode {
        case .active:
            if v < cfg.lowSpeedKmh {
                if lowSpeedStartTime == nil { lowSpeedStartTime = now }
                if let t0 = lowSpeedStartTime, now.timeIntervalSince(t0) >= cfg.lowSpeedDwellSec {
                    location.setSamplingMode(.idle)
                    currentSamplingMode = .idle
                    lastSwitchTime = now
                    lowSpeedStartTime = nil
                }
            } else {
                lowSpeedStartTime = nil
            }
        case .idle:
            if v >= cfg.resumeSpeedKmh {
                location.setSamplingMode(.active)
                currentSamplingMode = .active
                lastSwitchTime = now
                lowSpeedStartTime = nil
            }
        }
    }
}





/*
 
 // Recording/Domain/BasicSessionRecorder.swift
 import Foundation
 import CoreLocation

 // 自适应采样参数（保持原有）
 struct AdaptiveConfig {
     var lowSpeedKmh: Double = 2.5
     var resumeSpeedKmh: Double = 4.0
     var lowSpeedDwellSec: TimeInterval = 30
     var warmupIgnoreSec: TimeInterval = 5     // 适配判定冷启动忽略
     var minSwitchIntervalSec: TimeInterval = 10
 }

 // ✅ 新增：首定位防抖参数
 struct WarmupConfig {
     var accuracyThresholdM: CLLocationAccuracy = 25       // 满足此精度才计为“好样本”
     var minGoodSamples: Int = 3                           // 连续好样本数量
     var maxWarmupSec: TimeInterval = 10                   // 最长等待
 }

 final class BasicSessionRecorder: SessionRecorder {
     private let location: LocationService
     private let metrics: MetricsComputer
     private var ticker: Task<Void, Never>?

     private(set) var state: RecordingState = .idle

     private var cfg = AdaptiveConfig()
     private var warm = WarmupConfig()

     // 会话时间点
     private var sessionStartTime: Date?
     private var lastSwitchTime: Date?

     // 低速驻留
     private var lowSpeedStartTime: Date?

     // 采样模式
     private var currentSamplingMode: SamplingMode = .active

     // ✅ 首定位防抖状态
     private var isWarmingUp = false
     private var goodSampleCount = 0

     init(location: LocationService, metrics: MetricsComputer) {
         self.location = location
         self.metrics = metrics

         self.location.onSample = { [weak self] loc in
             guard let self else { return }
             self.handleIncomingSample(loc)
         }
     }

     // Exposed to VM/UI
     var currentSpeedKmh: Double { metrics.currentSpeedKmh }
     var distanceKm: Double { metrics.distanceKm }
     var durationSec: Int { metrics.durationSec }

     // MARK: - Session APIs
     func start(resortId: Int?) async {
         guard state == .idle else { return }
         metrics.reset()

         sessionStartTime = Date()
         lastSwitchTime = sessionStartTime
         lowSpeedStartTime = nil

         // ✅ 开启首定位防抖
         isWarmingUp = true
         goodSampleCount = 0

         await location.start()
         location.setSamplingMode(.active)
         currentSamplingMode = .active

         startTick()
         state = .recording
     }

     func pause() {
         guard state == .recording else { return }
         stopTick()
         location.setSamplingMode(.idle)
         currentSamplingMode = .idle
         lastSwitchTime = Date()
         state = .paused
     }

     func resume() {
         guard state == .paused else { return }
         startTick()
         location.setSamplingMode(.active)
         currentSamplingMode = .active
         lastSwitchTime = Date()
         state = .recording
     }

     // BasicSessionRecorder.swift
     @MainActor
     func stop() async -> SkiSession {
         // 先停掉内部计时
         stopTick()

         // 立刻把定位切到 idle 并停止，避免还有余波回调进来
         location.setSamplingMode(.idle)
         location.stop()

         // 🔴 关键：彻底断开回调，防止在弹 Sheet/动画时还有 onSample 喂数据
         if let cls = location as? CoreLocationService {
             cls.onSample = nil
         }

         state = .idle

         // 清理会话状态
         isWarmingUp = false
         goodSampleCount = 0
         sessionStartTime = nil
         lowSpeedStartTime = nil

         // finalize 很轻
         return metrics.finalize()
     }


     
     // MARK: - Internal ticking (1s)
     private func startTick() {
         stopTick()
         ticker = Task(priority: .userInitiated) { [weak self] in
             guard let self else { return }
             while !Task.isCancelled {
                 // 每秒推进一次时长
                 await MainActor.run { self.metrics.tick1s() }
                 try? await Task.sleep(nanoseconds: 1_000_000_000)
             }
         }
     }

     private func stopTick() {
         ticker?.cancel()
         ticker = nil
     }


     // MARK: - Sample pipeline
     private func handleIncomingSample(_ loc: CLLocation) {
         // 首定位防抖：满足条件前不进入指标管道
         if isWarmingUp {
             let good = (loc.horizontalAccuracy >= 0 &&
                         loc.horizontalAccuracy <= warm.accuracyThresholdM)

             if good { goodSampleCount += 1 } else { goodSampleCount = 0 }

             let warmupElapsed = Date().timeIntervalSince(sessionStartTime ?? Date())

             if goodSampleCount >= warm.minGoodSamples || warmupElapsed >= warm.maxWarmupSec {
                 // ✅ 结束暖机：从现在开始才把样本计入 metrics
                 isWarmingUp = false
                 goodSampleCount = 0
                 // 不回补历史（避免把抖动算进去）
             } else {
                 // 暖机中，直接返回
                 return
             }
         }

         // 到这里：样本才进入指标管道
         metrics.consume(loc)

         // 自适应采样（只在录制中）
         evaluateAdaptiveSampling()
     }

     // MARK: - Adaptive sampling
     private func evaluateAdaptiveSampling() {
         guard state == .recording else { return }

         let now = Date()

         // 适配采样的“冷启动忽略”，避免刚开始就误判低速
         if let start = sessionStartTime,
            now.timeIntervalSince(start) < cfg.warmupIgnoreSec {
             lowSpeedStartTime = nil
             return
         }

         // 模式切换最小间隔
         if let last = lastSwitchTime,
            now.timeIntervalSince(last) < cfg.minSwitchIntervalSec {
             return
         }

         let v = metrics.currentSpeedKmh

         switch currentSamplingMode {
         case .active:
             if v < cfg.lowSpeedKmh {
                 if lowSpeedStartTime == nil { lowSpeedStartTime = now }
                 if let t0 = lowSpeedStartTime,
                    now.timeIntervalSince(t0) >= cfg.lowSpeedDwellSec {
                     location.setSamplingMode(.idle)
                     currentSamplingMode = .idle
                     lastSwitchTime = now
                     lowSpeedStartTime = nil
                     // print("[Adaptive] -> idle")
                 }
             } else {
                 lowSpeedStartTime = nil
             }

         case .idle:
             if v >= cfg.resumeSpeedKmh {
                 location.setSamplingMode(.active)
                 currentSamplingMode = .active
                 lastSwitchTime = now
                 lowSpeedStartTime = nil
                 // print("[Adaptive] -> active")
             }
         }
     }
 }



 
 
 */
