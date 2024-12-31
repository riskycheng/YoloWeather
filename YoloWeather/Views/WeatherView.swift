import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationService = LocationService()
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingLocationPicker = false
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date = Date()
    @State private var isUsingCurrentLocation = false
    @State private var timeOfDay: WeatherTimeOfDay = .night
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            timeOfDay = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone)
        }
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        if isUsingCurrentLocation, let currentLocation = locationService.currentLocation {
            await weatherService.requestWeatherData(for: currentLocation)
        } else {
            locationService.locationName = selectedLocation.name
            await weatherService.requestWeatherData(for: selectedLocation.location)
        }
        lastRefreshTime = Date()
        
        // 更新时间状态
        updateTimeOfDay()
    }
    
    private var temperatureText: some View {
        Text("\(Int(round(weatherService.currentWeather?.temperature ?? 0)))")
            .font(.system(size: 200))
            .minimumScaleFactor(0.1)
            .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            .shadow(color: WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.5), radius: 3, x: 0, y: 0)
            .fontWeight(.light)
            .brightness(0.2)
    }
    
    private var weatherDescription: some View {
        Text(weatherService.currentWeather?.condition ?? "")
            .font(.title)
            .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
    }
    
    private var temperatureRange: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
            Text("\(Int(round(weatherService.dailyForecast.first?.lowTemperature ?? 0)))°")
            Text("—")
            Image(systemName: "arrow.up")
            Text("\(Int(round(weatherService.dailyForecast.first?.highTemperature ?? 0)))°")
        }
        .font(.title2)
        .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
    }
    
    var body: some View {
        ZStack {
            // 背景颜色
            WeatherThemeManager.shared.backgroundColor(for: timeOfDay)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top toolbar
                HStack(alignment: .center) {
                    Button {
                        showingLocationPicker = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .overlay {
                                        Circle()
                                            .stroke(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.3), lineWidth: 1)
                                    }
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await refreshWeather()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                            .frame(width: 44, height: 44)
                            .background {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .overlay {
                                        Circle()
                                            .stroke(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.3), lineWidth: 1)
                                    }
                            }
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                if let currentWeather = weatherService.currentWeather {
                    // Weather content
                    CurrentWeatherView(
                        location: locationService.locationName,
                        weather: currentWeather,
                        isLoading: weatherService.isLoading,
                        dailyForecast: weatherService.dailyForecast
                    )
                    .padding(.top, -44) // 向上移动位置文本，与按钮水平对齐
                    
                    // Bottom section with hourly forecast
                    if !weatherService.hourlyForecast.isEmpty {
                        HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                            .padding(.vertical, 24)
                            .padding(.horizontal, 16)
                    }
                } else {
                    Spacer()
                    WeatherLoadingView()
                    Spacer()
                }
            }
        }
        .onChange(of: weatherService.currentWeather) { _ in
            updateTimeOfDay()
        }
        .onAppear {
            if locationService.authorizationStatus == .authorizedWhenInUse {
                isUsingCurrentLocation = true
                locationService.startUpdatingLocation()
            }
            
            // 初始化时立即更新时间状态
            updateTimeOfDay()
            
            // 如果没有天气数据，请求更新
            if weatherService.currentWeather == nil {
                Task {
                    await refreshWeather()
                }
            }
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if isUsingCurrentLocation, let location = newLocation {
                Task {
                    await weatherService.requestWeatherData(for: location)
                }
            }
        }
        .alert("位置错误", isPresented: .constant(locationService.errorMessage != nil)) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(locationService.errorMessage ?? "")
        }
        .refreshable {
            await refreshWeather()
        }
        .environment(\.weatherTimeOfDay, timeOfDay)
        .sheet(isPresented: $showingLocationPicker) {
            NavigationView {
                LocationPickerView(
                    selectedLocation: $selectedLocation,
                    locationService: locationService,
                    isUsingCurrentLocation: $isUsingCurrentLocation,
                    onLocationSelected: { location in
                        Task {
                            if let location = location {
                                isUsingCurrentLocation = true
                                await weatherService.requestWeatherData(for: location)
                            } else {
                                isUsingCurrentLocation = false
                                locationService.locationName = selectedLocation.name
                                locationService.currentLocation = nil
                                await weatherService.requestWeatherData(for: selectedLocation.location)
                            }
                        }
                        showingLocationPicker = false
                    }
                )
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    WeatherView()
}
