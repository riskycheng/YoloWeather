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
        
        // 清除所有历史天气数据，避免数据混淆问题
        // 注意：这里只在应用首次安装或更新后清除数据
        let hasCleanedData = UserDefaults.standard.bool(forKey: "has_cleaned_historical_data_v1")
        if !hasCleanedData {
            WeatherService.shared.clearAllHistoricalWeatherData()
            UserDefaults.standard.set(true, forKey: "has_cleaned_historical_data_v1")
            print("已清除所有历史天气数据")
        }
        
        // 启动时立即初始化位置服务，开始获取位置
        LocationService.shared.startUpdatingLocation()
        print("应用启动：已开始请求位置权限并获取当前位置")
    }
    
    var body: some Scene {
        WindowGroup {
            WeatherView()
        }
    }
}
