import SwiftUI
import CoreLocation

struct LocationButton: View {
    @StateObject private var weatherService = WeatherService.shared
    @ObservedObject var timeOfDayManager: TimeOfDayManager
    @Binding var selectedLocation: PresetLocation
    @Binding var animationTrigger: UUID
    
    var body: some View {
        Button(action: {
            handleLocationButtonTap()
        }) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDayManager.timeOfDay))
        }
    }
    
    private func handleLocationButtonTap() {
        Task {
            do {
                // 获取位置信息
                let locationService = LocationService.shared
                
                // 先清除当前位置信息，确保能获取新的位置
                locationService.currentLocation = nil
                locationService.currentCity = nil
                
                try await locationService.requestLocation()
                
                // 如果请求成功但没有获取到位置信息，提前返回
                guard let location = locationService.currentLocation,
                      let cityName = locationService.currentCity else {
                    print("无法获取位置信息")
                    return
                }
                
                print("=== 位置信息 ===")
                print("经度：\(location.coordinate.longitude)")
                print("纬度：\(location.coordinate.latitude)")
                print("城市：\(cityName)")
                print("海拔：\(location.altitude)米")
                print("精确度：水平\(location.horizontalAccuracy)米, 垂直\(location.verticalAccuracy)米")
                print("================")
                
                // 1. 首先尝试在所有城市中查找匹配
                let cleanCityName = cityName.replacingOccurrences(of: "市", with: "")
                
                if let matchedCity = CitySearchService.shared.allCities.first(where: { $0.name.contains(cleanCityName) }) {
                    print("找到匹配的预设城市：\(matchedCity.name)")
                    selectedLocation = matchedCity
                    print("已切换到城市：\(matchedCity.name)")
                    
                    // 更新天气信息
                    await weatherService.updateWeather(for: matchedCity.location, cityName: matchedCity.name)
                    
                    // 触发动画更新
                    animationTrigger = UUID()
                } else {
                    print("在预设城市中未找到匹配，创建新的城市位置：\(cityName)")
                    let newLocation = PresetLocation(
                        name: cityName,
                        location: location,
                        timeZoneIdentifier: TimeZone.current.identifier
                    )
                    selectedLocation = newLocation
                    print("已切换到新创建的城市：\(cityName)")
                    
                    // 更新天气信息
                    await weatherService.updateWeather(for: location, cityName: cityName)
                    
                    // 触发动画更新
                    animationTrigger = UUID()
                }
            } catch {
                print("定位过程发生错误：\(error.localizedDescription)")
                // 确保清理任何未完成的请求
                LocationService.shared.cleanupCurrentRequest()
            }
        }
    }
}

// MARK: - Preview Provider
#Preview {
    LocationButton(timeOfDayManager: TimeOfDayManager(), 
                  selectedLocation: .constant(PresetLocation.presets[0]), 
                  animationTrigger: .constant(UUID()))
        .preferredColorScheme(.dark)
}