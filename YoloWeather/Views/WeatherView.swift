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
        
        if let location = locationService.currentLocation {
            await weatherService.updateWeather(for: location)
            lastRefreshTime = Date()
            updateTimeOfDay()
        }
    }
    
    private func updateLocation(_ location: CLLocation?) async {
        if let location = location {
            isUsingCurrentLocation = true
            locationService.currentLocation = location
            await weatherService.updateWeather(for: location)
        } else {
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
            WeatherBackgroundView(timeOfDay: timeOfDay)
            
            ScrollView {
                VStack(spacing: 24) {
                    // 顶部工具栏
                    HStack(spacing: 16) {
                        Button {
                            showingLocationPicker.toggle()
                        } label: {
                            toolbarButton("list.bullet")
                        }
                        
                        Spacer()
                        
                        // 城市名称
                        Text(locationService.locationName ?? selectedLocation.name)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                withAnimation {
                                    showDailyForecast.toggle()
                                }
                            } label: {
                                toolbarButton(showDailyForecast ? "calendar.circle.fill" : "calendar.circle")
                            }
                            
                            Button {
                                Task {
                                    isRefreshing = true
                                    await weatherService.updateWeather(for: locationService.currentLocation ?? selectedLocation.location)
                                    isRefreshing = false
                                    lastRefreshTime = Date()
                                    updateTimeOfDay()
                                }
                            } label: {
                                toolbarButton("arrow.clockwise")
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                            }
                            .disabled(isRefreshing)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let currentWeather = weatherService.currentWeather {
                        // 当前天气
                        CurrentWeatherView(weather: currentWeather)
                            .transition(.opacity)
                    }
                    
                    if !weatherService.hourlyForecast.isEmpty {
                        // 24小时预报
                        HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                            .transition(.opacity)
                            .padding(.horizontal)
                    }
                    
                    if !weatherService.dailyForecast.isEmpty && showDailyForecast {
                        // 7天预报
                        DailyForecastView(forecast: weatherService.dailyForecast)
                            .transition(.opacity)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await refreshWeather()
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            NavigationView {
                LocationPickerView(
                    selectedLocation: $selectedLocation,
                    locationService: locationService,
                    isUsingCurrentLocation: $isUsingCurrentLocation,
                    onLocationSelected: { location in
                        Task {
                            await updateLocation(location)
                            showingLocationPicker = false
                        }
                    }
                )
            }
        }
        .task {
            await updateLocation(selectedLocation.location)
        }
        .onChange(of: selectedLocation) { _ in
            Task {
                await updateLocation(selectedLocation.location)
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
