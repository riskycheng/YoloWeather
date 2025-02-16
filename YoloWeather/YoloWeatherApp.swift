//
//  YoloWeatherApp.swift
//  YoloWeather
//
//  Created by Jian Cheng on 2024/12/28.
//

import SwiftUI
import WidgetKit

@main
struct YoloWeatherApp: App {
    init() {
        // Ensure widgets are reloaded when app launches
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    var body: some Scene {
        WindowGroup {
            WeatherView()
        }
    }
}
