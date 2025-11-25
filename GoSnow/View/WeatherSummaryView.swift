//
//  WeatherSummaryView.swift
//  GoSnow
//
//  Created by federico Liu on 2024/6/18.
//
/*
import SwiftUI
import WeatherKit

struct WeatherSummaryView: View {
    let weather: Weather

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: weather.currentWeather.symbolName)
                    .font(.title2)
                Text("\(Int(weather.currentWeather.temperature.value))°\(weather.currentWeather.temperature.unit.symbol)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Image(systemName: "thermometer.snowflake")
                    .font(.caption)
                Text("Feels like \(Int(weather.currentWeather.feelsLikeTemperature.value))°\(weather.currentWeather.feelsLikeTemperature.unit.symbol)")
                    .font(.caption)
            }
            
            HStack {
                Image(systemName: "wind")
                    .font(.caption)
                Text("\(Int(weather.currentWeather.windSpeed.value)) \(weather.currentWeather.windSpeed.unit.symbol)")
                    .font(.caption)
            }
            
            if let snowAccumulation = weather.snowfallIntensity {
                HStack {
                    Image(systemName: "snowflake")
                        .font(.caption)
                    Text("Snow: \(snowAccumulation.value) \(snowAccumulation.unit.symbol)")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.8))
        )
    }
}


#Preview {
    WeatherSummaryView(weather: <#Weather#>)
}

*/
