//
//  LocationManager.swift
//  GoSnow
//
//  Created by federico Liu on 2024/8/21.
//
import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation? // Current user location
    private var locationManager = CLLocationManager()
    private var webSocketTask: URLSessionWebSocketTask?
    private let apiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImV4cCI6MzMwMjA1OTI5MSwiaWF0IjoxNzI1MjU5MjkxLCJpc3MiOiJzdXBhYmFzZSJ9.FYvFCQVIJn-iL-t9lxYOSzD__jJZMQMDtynLh-wTyHQ"

    override init() {
        super.init()
        setupWebSocket()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func setupWebSocket() {
        // 正确的 WebSocket URL
        let url = URL(string: "wss://crals6q5g6h44cne3j40.baseapi.memfiredb.com/realtime/v1")!
        var request = URLRequest(url: url)
        
        // 添加 Authorization 头
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // 创建 WebSocket 任务
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessages()
    }

    func sendLocationUpdate() {
        guard let location = currentLocation else { return }
        let locationData = ["lat": location.coordinate.latitude, "lon": location.coordinate.longitude]
        guard let data = try? JSONSerialization.data(withJSONObject: locationData, options: []) else { return }
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Received data: \(data)")
                    // Parse and handle incoming data to update friends' locations
                default:
                    break
                }
            }
            self?.receiveMessages()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Update only if location change is significant (e.g., > 500 meters)
        if let currentLocation = currentLocation, currentLocation.distance(from: newLocation) < 500 {
            return
        }
        
        DispatchQueue.main.async {
            self.currentLocation = newLocation
            self.sendLocationUpdate() // Send location update via WebSocket
        }
    }
    
    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}









