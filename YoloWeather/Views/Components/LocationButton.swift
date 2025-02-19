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
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDayManager.timeOfDay))
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.black.opacity(0.3))
                        .overlay {
                            Circle()
                                .stroke(WeatherThemeManager.shared.textColor(for: timeOfDayManager.timeOfDay).opacity(0.3), lineWidth: 1)
                        }
                }
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
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
                
                // 请求位置更新
                try await locationService.requestLocation()
                
                // 如果请求成功但没有获取到位置信息，提前返回
                guard let location = locationService.currentLocation,
                      let locationName = locationService.currentCity else {
                    print("无法获取位置信息")
                    return
                }
                
                print("=== 位置信息 ===")
                print("经度：\(location.coordinate.longitude)")
                print("纬度：\(location.coordinate.latitude)")
                print("位置：\(locationName)")
                print("海拔：\(location.altitude)米")
                print("精确度：水平\(location.horizontalAccuracy)米, 垂直\(location.verticalAccuracy)米")
                print("================")
                
                // 创建新的位置对象
                let newLocation = PresetLocation(
                    name: locationName,
                    location: location,
                    timeZoneIdentifier: TimeZone.current.identifier
                )
                
                // 更新天气信息
                await weatherService.updateWeather(for: location, cityName: locationName)
                
                // 更新选中的城市
                withAnimation(.easeInOut) {
                    selectedLocation = newLocation
                }
                
                print("已切换到位置：\(locationName)")
                
                // 触发动画更新
                animationTrigger = UUID()
                
                // 保存最后选择的位置
                UserDefaults.standard.set(locationName, forKey: "LastSelectedCity")
                
                // 发送通知以更新其他视图
                NotificationCenter.default.post(name: .weatherDataDidUpdate, object: nil)
            } catch LocationError.permissionDenied {
                print("位置权限被拒绝")
                // 这里可以添加提示用户开启位置权限的逻辑
            } catch LocationError.timeout {
                print("位置请求超时，请重试")
                // 这里可以添加重试逻辑
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