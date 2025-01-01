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
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            timeOfDay = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone)
        }
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await weatherService.updateWeather()
        lastRefreshTime = Date()
        updateTimeOfDay()
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            WeatherBackgroundView(timeOfDay: timeOfDay)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 位置信息
                    WeatherLocationHeaderView(
                        location: locationService.locationName ?? selectedLocation.name,
                        isLoading: isRefreshing
                    )
                    
                    if let currentWeather = weatherService.currentWeather {
                        // 当前天气
                        CurrentWeatherView(weather: currentWeather)
                            .transition(.opacity)
                    }
                    
                    if !weatherService.hourlyForecast.isEmpty {
                        // 24小时预报
                        HourlyTemperatureTrendView(forecast: weatherService.hourlyForecast)
                            .transition(.opacity)
                    }
                    
                    if !weatherService.dailyForecast.isEmpty {
                        // 7天预报
                        DailyForecastView(forecast: weatherService.dailyForecast)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)
            }
            .refreshable {
                await refreshWeather()
            }
            
            // 工具栏
            VStack {
                HStack {
                    Button {
                        showingLocationPicker.toggle()
                    } label: {
                        toolbarButton("list.bullet")
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await refreshWeather()
                        }
                    } label: {
                        toolbarButton("arrow.clockwise")
                    }
                }
                .padding()
                
                Spacer()
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
                            if let location = location {
                                isUsingCurrentLocation = true
                                locationService.currentLocation = location
                            } else {
                                isUsingCurrentLocation = false
                                locationService.locationName = selectedLocation.name
                                locationService.currentLocation = nil
                            }
                            await refreshWeather()
                        }
                        showingLocationPicker = false
                    }
                )
            }
        }
        .task {
            await refreshWeather()
        }
        .onChange(of: selectedLocation) { _ in
            Task {
                await refreshWeather()
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
