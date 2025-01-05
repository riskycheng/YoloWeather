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
    
    private var hourlyForecastView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(weatherService.hourlyForecast) { forecast in
                    VStack(spacing: 8) {
                        Text(forecast.formattedTime)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                        
                        WeatherSymbol(symbolName: forecast.symbolName)
                            .frame(width: 25, height: 25)
                        
                        Text("\(Int(round(forecast.temperature)))°")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.2))
        .cornerRadius(15)
    }
    
    struct WeatherSymbol: View {
        let symbolName: String
        
        var body: some View {
            Image(systemName: symbolName)
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.yellow, .white)
                .font(.system(size: 25))
        }
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            WeatherBackgroundView(
                weatherService: weatherService,
                weatherCondition: weatherService.currentWeather?.condition ?? "晴天"
            )
            .environment(\.weatherTimeOfDay, timeOfDay)
            .environmentObject(weatherService)  // 添加 weatherService 作为环境对象
            
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
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                showingLocationPicker = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        
                        Spacer()
                        
                        // Right control - Day/Night toggle
                        DayNightToggle(isNight: Binding(
                            get: { timeOfDay == .night },
                            set: { isNight in
                                withAnimation {
                                    timeOfDay = isNight ? .night : .day
                                }
                            }
                        ))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    Spacer()
                    
                    // Weather information at the bottom
                    VStack(alignment: .leading, spacing: 0) {
                        // City name and condition
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isUsingCurrentLocation ? locationService.locationName : selectedLocation.name)
                                .font(.system(size: 34, weight: .medium))
                                .foregroundColor(timeOfDay == .day ? .white : .gray.opacity(0.8))
                            
                            if let weather = weatherService.currentWeather {
                                Text(weather.condition)
                                    .font(.system(size: 17))
                                    .foregroundColor(timeOfDay == .day ? .white : .gray.opacity(0.8))
                                    .opacity(0.8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        
                        // Large temperature
                        if let weather = weatherService.currentWeather {
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(size: 96, weight: .thin))
                                .foregroundColor(timeOfDay == .day ? .white : .gray.opacity(0.8))
                                .padding(.leading, 10)
                        }
                        
                        Spacer().frame(height: 30)
                        
                        // Hourly forecast
                        if !weatherService.hourlyForecast.isEmpty {
                            hourlyForecastView
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
