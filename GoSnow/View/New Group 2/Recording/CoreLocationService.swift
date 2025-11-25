//
//  CoreLocationService.swift
//  雪兔滑行
//
//  Created by federico Liu on 2025/8/10.
//

import Foundation
import CoreLocation

public enum SamplingMode { case active, idle }

public protocol LocationService: AnyObject {
    var onSample: ((CLLocation) -> Void)? { get set }
    func start() async
    func stop()
    func setSamplingMode(_ mode: SamplingMode)
}
final class CoreLocationService: NSObject, LocationService {
    private let manager = CLLocationManager()
    var onSample: ((CLLocation) -> Void)?

    private var hasBackgroundLocationMode: Bool {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        return modes.contains("location")
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = true
        manager.desiredAccuracy = kCLLocationAccuracyBest   // 你希望一开始就高精度
        manager.distanceFilter = 5
        manager.allowsBackgroundLocationUpdates = false     // 先关，等条件满足再开
        manager.showsBackgroundLocationIndicator = false
    }

    func start() async {
        // 1) 先拿到 WhenInUse
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return
        }

        // 2) 如果只有 WhenInUse，升级 Always（要在前台调用）
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
            return
        }

        // 3) 到这里如果不是 Always，就只在前台跑，别开后台
        let isAlways = (manager.authorizationStatus == .authorizedAlways)

        if hasBackgroundLocationMode && isAlways {
            // ✅ 只有“勾了 Background Modes”且“授权=Always”才允许后台
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
        } else {
            manager.allowsBackgroundLocationUpdates = false
            manager.showsBackgroundLocationIndicator = false
        }

        // （可选）如果用户把“精准定位”关了，这里可以尝试要一次临时精准。
        // 你说不强求，那就删掉这个块；要保留就解除注释。
        /*
        if #available(iOS 14.0, *) {
            if manager.accuracyAuthorization != .fullAccuracy {
                do { try await manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "SkiRecording") }
                catch { print("Temp full accuracy failed:", error) }
            }
        }
        */

        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false
        manager.pausesLocationUpdatesAutomatically = true
    }

    func setSamplingMode(_ mode: SamplingMode) {
        switch mode {
        case .active:
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = 5
            manager.pausesLocationUpdatesAutomatically = false
        case .idle:
            manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            manager.distanceFilter = 25
            manager.pausesLocationUpdatesAutomatically = true
        }
    }
}

extension CoreLocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // 授权变化（比如用户刚给了 Always）→ 重新尝试启动
        Task { await start() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        onSample?(last)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}



/*
 
 import Foundation
 import CoreLocation

 public enum SamplingMode { case active, idle }

 public protocol LocationService: AnyObject {
     var onSample: ((CLLocation) -> Void)? { get set }
     func start() async
     func stop()
     func setSamplingMode(_ mode: SamplingMode)
 }

 final class CoreLocationService: NSObject, LocationService {
     private let manager = CLLocationManager()
     var onSample: ((CLLocation) -> Void)?

     override init() {
         super.init()
         manager.delegate = self
         manager.activityType = .fitness
         manager.pausesLocationUpdatesAutomatically = true
         manager.allowsBackgroundLocationUpdates = true
         // 初始保守配置，具体参数后续由 setSamplingMode 调整
         manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
         manager.distanceFilter = 25
     }

     func start() async {
         // TODO: 权限流程优化（WhenInUse -> Always 可选）
         if manager.authorizationStatus == .notDetermined {
             manager.requestWhenInUseAuthorization()
         }
         manager.startUpdatingLocation()
     }

     func stop() {
         manager.stopUpdatingLocation()
     }

     func setSamplingMode(_ mode: SamplingMode) {
         switch mode {
         case .active:
             manager.desiredAccuracy = kCLLocationAccuracyBest
             manager.distanceFilter = 5
         case .idle:
             manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
             manager.distanceFilter = 25
         }
     }
 }

 extension CoreLocationService: CLLocationManagerDelegate {
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
         guard let last = locations.last else { return }
         onSample?(last)
     }
     func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
     func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print("Location error: \(error)")
     }
 }
 
 
 */
