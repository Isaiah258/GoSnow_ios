//
//  MapViewRepresentable.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/21.
//
import SwiftUI
import MapKit
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var userLocation: CLLocationCoordinate2D?
    let onMapViewCreated: (MKMapView) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // 交互&显示选项
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true

        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.mapType = .standard

        // 初始相机范围
        mapView.setCameraZoomRange(
            MKMapView.CameraZoomRange(minCenterCoordinateDistance: 150,
                                      maxCenterCoordinateDistance: 50_000),
            animated: false
        )

        onMapViewCreated(mapView)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 刻意留空：避免与外层抢相机控制
    }

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(self)
    }

    final class MapCoordinator: NSObject, MKMapViewDelegate {
        let parent: MapViewRepresentable
        init(_ parent: MapViewRepresentable) { self.parent = parent }

        // ✅ 把蓝点的坐标回传给上层（这是你现在缺的环节）
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if let coord = userLocation.location?.coordinate {
                parent.userLocation = coord
            }
        }
    }
}









/*
import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    
    let mapView = MKMapView()
    let locationManager = LocationManager() // 确保 LocationManager 正确配置
    
    func makeUIView(context: Context) -> some UIView {
        mapView.delegate = context.coordinator
        mapView.isRotateEnabled = true // 启用地图旋转
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // 设置地图类型为卫星实景图
        mapView.mapType = .satelliteFlyover

        // 设置初始相机位置（例如：倾斜 45 度）
        let initialCamera = MKMapCamera(lookingAtCenter: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), fromDistance: 1000, pitch: 45, heading: 0)
        mapView.setCamera(initialCamera, animated: false)

        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // 在这里进行更新操作
    }
    
    func makeCoordinator() -> MapCoordinator {
        return MapCoordinator(parent: self)
    }
}

extension MapViewRepresentable {
    class MapCoordinator: NSObject, MKMapViewDelegate {
        let parent: MapViewRepresentable
        
        init(parent: MapViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            
            parent.mapView.setRegion(region, animated: true)
        }
    }
}

*/
