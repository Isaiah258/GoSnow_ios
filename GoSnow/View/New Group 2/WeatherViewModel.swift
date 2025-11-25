//
//  WeatherViewModel.swift
//  GoSnow
//
//  Created by federico Liu on 2024/10/10.
//
/*
import SwiftUI
import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var temperature: Double = 0.0
    @Published var weatherDescription: String = "未知"
    @Published var windSpeed: Double = 0.0 // 风速（米/秒）
    @Published var windLevel: Int = 0 // 风力等级
    @Published var weatherIconName: String = "questionmark" // 默认图标
    
    private var weatherService = WeatherService.shared
    private var lastFetchedLocation: CLLocation?
    
    private let cacheKey = "cachedWeatherData" // 缓存的 key
    private let cacheExpiration: TimeInterval = 60 * 60 * 6 // 缓存 6 小时有效
    
    // 获取缓存的天气数据
    private func getCachedWeatherData() -> Weather? {
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedWeather = try? JSONDecoder().decode(CachedWeather.self, from: cachedData),
           Date().timeIntervalSince(cachedWeather.timestamp) < cacheExpiration {
            return cachedWeather.weather
        }
        return nil
    }
    
    // 存储缓存的天气数据
    private func cacheWeatherData(weather: Weather) {
        let cachedWeather = CachedWeather(weather: weather, timestamp: Date())
        if let encodedData = try? JSONEncoder().encode(cachedWeather) {
            UserDefaults.standard.set(encodedData, forKey: cacheKey)
        }
    }
    
    // 更新天气数据
    private func updateWeatherData(weather: Weather) {
        self.temperature = weather.currentWeather.temperature.converted(to: .celsius).value
        self.windSpeed = weather.currentWeather.wind.speed.value // 直接从 WeatherKit 获取风速
        
        // 根据风速计算风力等级
        self.windLevel = calculateWindLevel(speed: windSpeed)
        
        // 更新天气描述及对应图标
        switch weather.currentWeather.condition {
        case .clear, .mostlyClear, .partlyCloudy:
            self.weatherDescription = "晴"
            self.weatherIconName = "sun.max.fill" // 晴天图标
        case .snow, .blowingSnow, .flurries:
            self.weatherDescription = "降雪"
            self.weatherIconName = "snow" // 降雪图标
        case .cloudy, .mostlyCloudy:
            self.weatherDescription = "多云"
            self.weatherIconName = "cloud" // 多云图标
        default:
            self.weatherDescription = "未知"
            self.weatherIconName = "questionmark" // 未知天气图标
        }
    }
    
    // 根据风速计算风力等级（例如使用 Beaufort 风级标准）
    private func calculateWindLevel(speed: Double) -> Int {
        switch speed {
        case 0..<0.3:
            return 0 // 无风
        case 0.3..<1.6:
            return 1 // 软风
        case 1.6..<3.4:
            return 2 // 轻风
        case 3.4..<5.5:
            return 3 // 微风
        case 5.5..<8.0:
            return 4 // 和风
        case 8.0..<10.8:
            return 5 // 清风
        case 10.8..<13.9:
            return 6 // 强风
        case 13.9..<17.2:
            return 7 // 疾风
        case 17.2..<20.8:
            return 8 // 大风
        case 20.8..<24.5:
            return 9 // 烈风
        case 24.5..<28.5:
            return 10 // 狂风
        case 28.5..<32.7:
            return 11 // 暴风
        case 32.7...:
            return 12 // 飓风
        default:
            return 0
        }
    }
    
    // 请求天气数据并缓存
    func fetchWeatherIfNeeded(for location: CLLocation) async {
        guard lastFetchedLocation == nil || location.distance(from: lastFetchedLocation!) > 5000 else {
            return
        }
        
        // 检查缓存
        if let cachedWeather = getCachedWeatherData() {
            updateWeatherData(weather: cachedWeather)
            print("使用缓存的天气数据")
            return
        }
        
        // 如果没有有效缓存，进行网络请求
        do {
            let weather = try await weatherService.weather(for: location)
            updateWeatherData(weather: weather)
            cacheWeatherData(weather: weather) // 缓存数据
            lastFetchedLocation = location
            print("成功获取并缓存天气数据")
        } catch {
            print("获取天气数据失败: \(error)")
        }
    }
}

// 定义一个结构体来保存天气数据和缓存的时间戳
struct CachedWeather: Codable {
    let weather: Weather
    let timestamp: Date
}






*/
