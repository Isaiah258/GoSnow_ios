//
//  RecordingView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/4.
//


import SwiftUI
import MapKit
import CoreLocation
import Snap

struct RecordingView: View {
    @State private var is3DMode = false
    @State private var isSatelliteMode = false
    @State private var mapView: MKMapView?

    @State private var userLocation: CLLocationCoordinate2D?
    @State private var didSetInitialCamera = false

    // 结束流程遮罩
    @State private var isEnding = false
    @State private var showMap = true

    // 总结数据
    @State private var summaryToPresent: SessionSummary? = nil

    // 本地权限请求器（只为蓝点&跟随）
    private let authLM = CLLocationManager()

    // 坐标变更“键”（避免频繁相机抖动）
    private struct CoordKey: Equatable {
        let lat: Int
        let lon: Int
    }
    private var userLocationKey: CoordKey? {
        guard let c = userLocation else { return nil }
        return CoordKey(
            lat: Int(c.latitude  * 1_000_000),
            lon: Int(c.longitude * 1_000_000)
        )
    }

    var body: some View {
        ZStack {
            if showMap { MapBlock }

            // 右侧抽屉（你的 Recents）
            ControlBlock
                .allowsHitTesting(!isEnding)
                .opacity(isEnding ? 0.4 : 1)

            // ✅ 右侧“浮动区”——与原代码一致：竖排两个按钮（2D/3D、标准/卫星）
            RightSideControls
                .allowsHitTesting(!isEnding)
                .opacity(isEnding ? 0.4 : 1)

            // 结束遮罩
            if isEnding {
                Color.black.opacity(0.001).ignoresSafeArea()
                ProgressView("保存中…")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            didSetInitialCamera = false
            ensureMapAuthorization()   // 进入时申请定位权限（让蓝点能出现）
        }
        .fullScreenCover(item: $summaryToPresent) { s in
            SessionSummaryScreen(summary: s) {
                // 关闭总结：关 cover + 恢复地图交互 & 跟随
                summaryToPresent = nil
                isEnding = false
                showMap = true
                if let map = mapView {
                    map.isUserInteractionEnabled = true
                    map.setUserTrackingMode(.follow, animated: false)
                }
            }
        }
    }

    // MARK: - 地图块
    private var MapBlock: some View {
        MapViewRepresentable(userLocation: $userLocation) { map in
            DispatchQueue.main.async {
                self.mapView = map

                // 初始配置（保持与原思路一致）
                map.mapType = isSatelliteMode ? .satellite : .standard
                map.pointOfInterestFilter = .includingAll
                map.showsUserLocation = true
                map.setUserTrackingMode(.follow, animated: false)

                map.isZoomEnabled = true
                map.isScrollEnabled = true
                map.isRotateEnabled = true
                map.isPitchEnabled = true
                map.showsCompass = true

                // 没有坐标时，尽量给个近似镜头
                if self.userLocation == nil {
                    if let approx = authLM.location?.coordinate {
                        let camera = MKMapCamera(lookingAtCenter: approx,
                                                 fromDistance: is3DMode ? 1000 : 3000,
                                                 pitch: is3DMode ? 45 : 0,
                                                 heading: 0)
                        map.setCamera(camera, animated: false)
                    }
                }
            }
        }
        .ignoresSafeArea()
        // 首次把相机拉到正确位置；之后交给 .follow
        .onChange(of: userLocationKey) { _, _ in
            guard let coord = userLocation, let map = self.mapView else { return }
            if !didSetInitialCamera {
                didSetInitialCamera = true
                let cam = MKMapCamera(lookingAtCenter: coord,
                                      fromDistance: is3DMode ? 1000 : 3000,
                                      pitch: is3DMode ? 45 : 0, heading: 0)
                map.setCamera(cam, animated: true)
                map.setUserTrackingMode(.follow, animated: false)
            }
        }
    }

    // MARK: - 控制抽屉（含 Recents）
    // 保留你的抽屉与结束流程逻辑，不再在抽屉里放地图按钮条
    private var ControlBlock: some View {
        VStack(spacing: 0) {
            Spacer()
            SnapDrawer(
                large: .paddingToTop(500),
                medium: .fraction(0.4),
                tiny: .height(100),
                allowInvisible: false
            ) { state in
                ZStack(alignment: .topTrailing) {
                    Recents(
                        onWillStop: { [weakMap = mapView] in
                            // 结束：先撤下重组件 & 禁止交互
                            isEnding = true
                            weakMap?.setUserTrackingMode(.none, animated: false)
                            weakMap?.isUserInteractionEnabled = false
                            weakMap?.delegate = nil
                            showMap = false
                        },
                        onSummary: { s in
                            // 完全错开后再展示总结页
                            summaryToPresent = s
                        }
                    )
                    .opacity(state == .tiny || isEnding ? 0 : 1)
                    .allowsHitTesting(state != .tiny && !isEnding)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - 右侧浮动区（2D/3D、标准/卫星）
    private var RightSideControls: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                // 2D / 3D
                Button {
                    is3DMode.toggle()
                    updateMapViewMode()
                } label: {
                    Image(systemName: is3DMode ? "view.3d" : "view.2d")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.gray)
                        .cornerRadius(15)
                }

                // 标准 / 卫星
                Button {
                    isSatelliteMode.toggle()
                    updateMapStyle()
                } label: {
                    Image(systemName: isSatelliteMode ? "map.fill" : "map")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.gray)
                        .cornerRadius(15)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 50)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - 定位权限（只负责让蓝点能出现）
    private func ensureMapAuthorization() {
        let status = authLM.authorizationStatus
        switch status {
        case .notDetermined:
            authLM.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    // MARK: - 与原版一致的地图更新方法
    private func updateMapViewMode() {
        guard let mapView = self.mapView else { return }
        // 按当前中心切换 2D/3D
        let camera = MKMapCamera(
            lookingAtCenter: mapView.centerCoordinate,
            fromDistance: is3DMode ? 1000 : 3000,
            pitch: is3DMode ? 45 : 0,
            heading: mapView.camera.heading
        )
        mapView.setCamera(camera, animated: true)
    }

    private func updateMapStyle() {
        guard let mapView = self.mapView else { return }
        // 与原代码相同的简洁实现
        mapView.mapType = isSatelliteMode ? .satelliteFlyover : .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
    }
}



/*
import SwiftUI
import Snap
import MapKit

struct RecordingView: View {
    @State private var is3DMode = false // 用于切换 2D/3D 模式
    @State private var isSatelliteMode = false // 用于切换地图风格
    @State private var mapView: MKMapView? // 保存 MKMapView 实例
    @State private var friendsLocations: [UUID: CLLocationCoordinate2D] = [:]
    
    var body: some View {
        ZStack {
            // 地图视图
            MapViewRepresentable { mapView in
                self.mapView = mapView
                configureFlatMapView(mapView) // 设置平面视角
            }
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        is3DMode.toggle()
                        updateMapViewMode()
                    }) {
                        Image(systemName: is3DMode ? "view.3d" : "view.2d")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.gray)
                            .cornerRadius(15)
                    }

                    Button(action: {
                        isSatelliteMode.toggle()
                        updateMapStyle()
                    }) {
                        Image(systemName: isSatelliteMode ? "map.fill" : "map")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.gray)
                            .cornerRadius(15)
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 50)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            SnapDrawer(large: .paddingToTop(500), medium: .fraction(0.4), tiny: .height(100), allowInvisible: false) { state in
                VStack(alignment: .leading, spacing: 10) {
                    if state != .tiny {
                        Recents()
                            .transition(.scale)
                    }
                }
                .padding()
            }
        }
    }

    private func configureFlatMapView(_ mapView: MKMapView) {
        let flatCamera = MKMapCamera(
            lookingAtCenter: mapView.centerCoordinate,
            fromDistance: 3000, // 设定一个较高的高度
            pitch: 0,          // 平面视角，无俯视角度
            heading: 0
        )
        mapView.setCamera(flatCamera, animated: false)
    }

    private func updateMapViewMode() {
        guard let mapView = mapView else { return }
        let altitude: CLLocationDistance = is3DMode ? 1000 : 3000
        let pitch: CGFloat = is3DMode ? 45 : 0
        let camera = MKMapCamera(
            lookingAtCenter: mapView.centerCoordinate,
            fromDistance: altitude,
            pitch: pitch,
            heading: 0
        )
        mapView.setCamera(camera, animated: true)
    }

    private func updateMapStyle() {
        guard let mapView = mapView else { return }
        mapView.mapType = isSatelliteMode ? .satelliteFlyover : .standard
    }
}





*/








/*struct RecordingView: View {
 @State private var region = MKCoordinateRegion(
 center: CLLocationCoordinate2D(latitude: 37.785834, longitude: -122.406417),
 span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
 )
 var body: some View {
 ZStack {
 Map(coordinateRegion: $region)
 //.frame(height: 700)
 //.mapStyle(.hybrid)
 .edgesIgnoringSafeArea(.all)
 
 
 VStack{
 Spacer()
 
 
 ZStack {
 SnapDrawer(large: .paddingToTop(500), medium: .fraction(0.4),tiny: .height(100), allowInvisible: false) { state in
 VStack(alignment: .leading, spacing: 10) {
 
 if state != .tiny {
 Favorites()
 .transition(.scale)
 }
 
 if state == .large {
 Recents()
 .transition(.scale)
 }
 }
 }
 }
 }
 }
 }
 }
 
 
 
 
 #Preview {
 RecordingView()
 }
 */


/*
 import SwiftUI
 import MapKit
 import Snap


 struct RecordingView: View {
     @State private var is3DMode = false
     @State private var isSatelliteMode = false // 默认非卫星地图
     @State private var mapView: MKMapView?
     @StateObject private var motionManager = CoreMotionManager()
     @State private var userLocation: CLLocationCoordinate2D?

     var body: some View {
         ZStack {
             MapViewRepresentable (userLocation: $userLocation) { mapView in
                 DispatchQueue.main.async { // 确保在主线程更新
                     self.mapView = mapView
                     configureMapView(mapView)
                 }
             }
             .ignoresSafeArea()
             .onReceive(motionManager.$currentLocation) { location in
                             if let location = location {
                                 userLocation = location.coordinate
                             }
                         }

             VStack {
                 Spacer()

                 VStack(spacing: 16) { // 保留原有的 VStack 布局
                     Button {
                         is3DMode.toggle()
                         updateMapViewMode()
                     } label: {
                         Image(systemName: is3DMode ? "view.3d" : "view.2d")
                             .resizable()
                             .frame(width: 20, height: 20)
                             .padding()
                             .background(Color.white)
                             .foregroundColor(.gray)
                             .cornerRadius(15)
                     }

                     Button {
                         isSatelliteMode.toggle()
                         updateMapStyle()
                     } label: {
                         Image(systemName: isSatelliteMode ? "map.fill" : "map")
                             .resizable()
                             .frame(width: 20, height: 20)
                             .padding()
                             .background(Color.white)
                             .foregroundColor(.gray)
                             .cornerRadius(15)
                     }
                 }
                 .padding(.trailing, 16)
                 .padding(.bottom, 50)

                 Spacer()
             }
             .frame(maxWidth: .infinity, alignment: .trailing)

             SnapDrawer(large: .paddingToTop(500), medium: .fraction(0.4), tiny: .height(100), allowInvisible: false) { state in
                 VStack(alignment: .leading, spacing: 10) {
                     if state != .tiny {
                         Recents()
                             .transition(.scale)
                     }
                 }
                 .padding()
             }
         }
     }

     private func configureMapView(_ mapView: MKMapView) {
         let camera = MKMapCamera(
             lookingAtCenter: mapView.centerCoordinate,
             fromDistance: 3000,
             pitch: 0,
             heading: 0
         )
         mapView.setCamera(camera, animated: false)
         mapView.mapType = isSatelliteMode ? .satelliteFlyover : .standard // 根据 isSatelliteMode 设置地图类型
     }

     private func updateMapViewMode() {
         guard let mapView = self.mapView else {
             print("mapView is nil in updateMapViewMode")
             return
         }
         let altitude: CLLocationDistance = is3DMode ? 1000 : 3000
         let pitch: CGFloat = is3DMode ? 45 : 0
         let camera = MKMapCamera(
             lookingAtCenter: mapView.centerCoordinate,
             fromDistance: altitude,
             pitch: pitch,
             heading: 0
         )
         mapView.setCamera(camera, animated: true)
     }

     private func updateMapStyle() {
         guard let mapView = self.mapView else {
             print("mapView is nil in updateMapStyle")
             return
         }
         mapView.mapType = isSatelliteMode ? .satelliteFlyover : .standard
     }
 }

 #Preview {
     RecordingView()
 }
 */
