import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationService = LocationService()
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingLocationPicker = false
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date = Date()
    @State private var isUsingCurrentLocation = false
    @State private var timeOfDay: WeatherTimeOfDay = .night
    @AppStorage("showDailyForecast") private var showDailyForecast = false
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            timeOfDay = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone)
        }
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        if isUsingCurrentLocation {
            if let location = locationService.currentLocation {
                await weatherService.updateWeather(for: location)
            }
        } else {
            locationService.locationName = selectedLocation.name
            await weatherService.updateWeather(for: selectedLocation.location)
        }
        lastRefreshTime = Date()
        updateTimeOfDay()
    }
    
    private func updateLocation(_ location: CLLocation?) async {
        if let location = location {
            // 使用当前位置
            isUsingCurrentLocation = true
            locationService.currentLocation = location
            await weatherService.updateWeather(for: location)
        } else {
            // 使用预设位置
            isUsingCurrentLocation = false
            locationService.locationName = selectedLocation.name
            locationService.currentLocation = selectedLocation.location
            await weatherService.updateWeather(for: selectedLocation.location)
        }
        lastRefreshTime = Date()
        updateTimeOfDay()
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            WeatherBackgroundView(
                weatherCondition: weatherService.currentWeather?.condition ?? "晴天"
            )
            .environment(\.weatherTimeOfDay, timeOfDay)
            
            // 主内容
            RefreshableView(isRefreshing: $isRefreshing) {
                Task {
                    await refreshWeather()
                }
            } content: {
                VStack(spacing: 0) {
                    // Top bar with controls
                    HStack(spacing: 20) {
                        // Left controls
                        HStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    if let location = locationService.currentLocation {
                                        await updateLocation(location)
                                    }
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.brown)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                showingLocationPicker = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.brown)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Spacer()
                        
                        // Right control - Day/Night toggle
                        Button(action: {
                            withAnimation {
                                timeOfDay = timeOfDay == .day ? .night : .day
                            }
                        }) {
                            Image(systemName: timeOfDay == .day ? "sun.max.fill" : "moon.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(timeOfDay == .day ? .yellow : .gray)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    Spacer()
                    
                    // Weather information at the bottom
                    VStack(alignment: .leading, spacing: 0) {
                        // City name and condition
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isUsingCurrentLocation ? locationService.locationName : selectedLocation.name)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            if let weather = weatherService.currentWeather {
                                Text(weather.condition)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        
                        // Large temperature
                        if let weather = weatherService.currentWeather {
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(size: 140, weight: .bold))
                                .foregroundStyle(.primary)
                                .padding(.leading, 10)
                        }
                        
                        Spacer().frame(height: 30)
                        
                        // Hourly forecast
                        if !weatherService.hourlyForecast.isEmpty {
                            HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                                .frame(height: 100)
                                .padding(.horizontal)
                                .padding(.bottom, 30)
                        }
                    }
                }
            }
            
            // Location picker sheet
            .sheet(isPresented: $showingLocationPicker) {
                NavigationView {
                    LocationPickerView(
                        selectedLocation: $selectedLocation,
                        locationService: locationService,
                        isUsingCurrentLocation: $isUsingCurrentLocation,
                        onLocationSelected: { location in
                            showingLocationPicker = false
                            Task {
                                await updateLocation(location)
                            }
                        }
                    )
                }
            }
        }
        .task {
            // 首次加载时更新天气
            await updateLocation(selectedLocation.location)
        }
        .onChange(of: selectedLocation) { oldValue, newValue in
            // 切换城市时更新天气
            Task {
                await updateLocation(newValue.location)
            }
        }
    }
    
    @ViewBuilder
    private func toolbarButton(_ systemName: String) -> some View {
        let textColor = WeatherThemeManager.shared.textColor(for: timeOfDay)
        Image(systemName: systemName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(textColor)
            .frame(width: 44, height: 44)
            .background {
                Circle()
                    .fill(.black.opacity(0.3))
                    .overlay {
                        Circle()
                            .stroke(textColor.opacity(0.3), lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
