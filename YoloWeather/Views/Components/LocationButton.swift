import SwiftUI
import CoreHaptics
import CoreLocation

struct LocationButton: View {
    @StateObject private var locationService = LocationService.shared
    @StateObject private var weatherService = WeatherService.shared
    @State private var engine: CHHapticEngine?
    @State private var isAnimating = false
    @Binding var selectedLocation: PresetLocation
    @Binding var animationTrigger: UUID
    
    var body: some View {
        Button(action: {
            handleLocationButtonTap()
        }) {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    isAnimating ? 
                        Animation
                            .easeInOut(duration: 0.8)
                            .repeatCount(1, autoreverses: false) : 
                        .default,
                    value: isAnimating
                )
        }
        .buttonStyle(LocationButtonStyle())
        .onAppear(perform: prepareHaptics)
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine creation error: \(error.localizedDescription)")
        }
    }
    
    private func complexSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else { return }
        
        var events = [CHHapticEvent]()
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription)")
        }
    }
    
    private func handleLocationButtonTap() {
        print("\n=== 开始定位流程 ===")
        
        // 触发震动反馈
        complexSuccess()
        
        // 触发动画
        isAnimating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isAnimating = false
        }
        
        // 开始定位
        Task {
            do {
                print("正在请求位置权限和更新...")
                try await locationService.requestLocation()
                
                // 确保我们有位置和城市信息
                guard let location = locationService.currentLocation,
                      let cityName = locationService.currentCity else {
                    print("错误：未能获取完整的位置信息")
                    throw LocationError.locationUnavailable
                }
                
                print("成功获取位置：\(location.coordinate.latitude), \(location.coordinate.longitude)")
                print("当前城市名称：\(cityName)")
                
                // 1. 首先尝试在所有城市中查找匹配
                let cleanCityName = cityName.replacingOccurrences(of: "市", with: "")
                print("清理后的城市名称：\(cleanCityName)")
                
                if let matchedCity = CitySearchService.shared.allCities.first(where: { $0.name.contains(cleanCityName) }) {
                    print("找到匹配的预设城市：\(matchedCity.name)")
                    selectedLocation = matchedCity
                    print("已切换到城市：\(matchedCity.name)")
                    
                    // 更新天气信息
                    print("开始更新天气信息...")
                    await weatherService.updateWeather(for: matchedCity.location, cityName: matchedCity.name)
                    print("天气信息更新完成")
                    
                    // 更新主题
                    if let weather = weatherService.currentWeather {
                        print("\n=== 更新时间主题 ===")
                        var calendar = Calendar.current
                        calendar.timeZone = weather.timezone
                        let hour = calendar.component(.hour, from: Date())
                        
                        // 根据当地时间判断是否是白天（6:00-18:00为白天）
                        let timeOfDay: WeatherTimeOfDay = (hour >= 6 && hour < 18) ? .day : .night
                        print("城市时区：\(weather.timezone.identifier)")
                        print("当地时间：\(hour)点")
                        print("使用主题：\(timeOfDay == .day ? "白天" : "夜晚")")
                        
                        // 通知 WeatherView 更新主题
                        NotificationCenter.default.post(name: .updateWeatherTimeOfDay, value: timeOfDay)
                        
                        // 触发动画更新
                        animationTrigger = UUID()
                    }
                } else {
                    // 2. 如果没有找到匹配的预设城市，创建一个新的位置
                    print("在预设城市中未找到匹配，创建新的城市位置：\(cityName)")
                    let newLocation = PresetLocation(
                        name: cityName,
                        location: location
                    )
                    selectedLocation = newLocation
                    print("已切换到新创建的城市：\(cityName)")
                    
                    // 更新天气信息
                    print("开始更新天气信息...")
                    await weatherService.updateWeather(for: location, cityName: cityName)
                    print("天气信息更新完成")
                    
                    // 更新主题
                    if let weather = weatherService.currentWeather {
                        print("\n=== 更新时间主题 ===")
                        var calendar = Calendar.current
                        calendar.timeZone = weather.timezone
                        let hour = calendar.component(.hour, from: Date())
                        
                        // 根据当地时间判断是否是白天（6:00-18:00为白天）
                        let timeOfDay: WeatherTimeOfDay = (hour >= 6 && hour < 18) ? .day : .night
                        print("城市时区：\(weather.timezone.identifier)")
                        print("当地时间：\(hour)点")
                        print("使用主题：\(timeOfDay == .day ? "白天" : "夜晚")")
                        
                        // 通知 WeatherView 更新主题
                        NotificationCenter.default.post(name: .updateWeatherTimeOfDay, value: timeOfDay)
                        
                        // 触发动画更新
                        animationTrigger = UUID()
                    }
                }
            } catch {
                print("定位过程发生错误：\(error.localizedDescription)")
                // 停止所有定位相关操作
                locationService.stopUpdatingLocation()
            }
        }
    }
}

// 自定义按钮样式
private struct LocationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    LocationButton(selectedLocation: .constant(PresetLocation.presets[0]), animationTrigger: .constant(UUID()))
        .preferredColorScheme(.dark)
} 