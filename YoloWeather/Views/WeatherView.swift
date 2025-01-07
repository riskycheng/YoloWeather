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
            // Use the current location name and coordinates
            if let currentLocation = locationService.currentLocation {
                await weatherService.updateWeather(for: currentLocation)
            }
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
    
    private func handleLocationButtonTap() {
        Task {
            // Request location authorization if needed
            locationService.requestLocationPermission()
            
            // Start updating location
            locationService.startUpdatingLocation()
            
            // Set to use current location
            isUsingCurrentLocation = true
            
            // Update weather with current location when available
            if let location = locationService.currentLocation {
                await weatherService.updateWeather(for: location)
                lastRefreshTime = Date()
                updateTimeOfDay()
            }
        }
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
            Image(symbolName)
                .resizable()
                .scaledToFit()
        }
    }
    
    private var locationButton: some View {
        Button {
            handleLocationButtonTap()
        } label: {
            HStack(spacing: 4) {
                if locationService.isLocating {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(WeatherThemeManager.shared.textColor(for: timeOfDay))
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                }
            }
            .frame(width: 44, height: 44)
        }
        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
    }
    
    private var cityPickerButton: some View {
        Button {
            showingLocationPicker = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
    }
    
    private var weatherIcon: some View {
        Group {
            if let weather = weatherService.currentWeather {
                let isNight = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone) == .night
                let symbolName = weatherService.getWeatherSymbolName(condition: weather.weatherCondition, isNight: isNight)
                
                Image(symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .offset(x: 60, y: -120)
                    .modifier(ScalingEffectModifier())
            }
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
            
            RefreshableView(isRefreshing: $isRefreshing) {
                await refreshWeather()
            } content: {
                VStack(spacing: 20) {
                    // 顶部工具栏
                    HStack {
                        locationButton
                        Spacer()
                        cityPickerButton
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 天气图标
                    weatherIcon
                    
                    // 城市名称和天气状况
                    if let weather = weatherService.currentWeather {
                        VStack(alignment: .leading, spacing: 0) {
                            // City name and condition
                            VStack(alignment: .leading, spacing: 4) {
                                Text(locationService.locationName)
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                                
                                Text(weather.condition)
                                    .font(.system(size: 17))
                                    .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay).opacity(0.8))
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                            
                            // Large temperature
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(size: 96, weight: .thin))
                                .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
                                .padding(.leading, 10)
                            
                            Spacer().frame(height: 30)
                            
                            // Hourly forecast
                            if !weatherService.hourlyForecast.isEmpty {
                                hourlyForecastView
                                    .frame(height: 100)
                                    .padding(.horizontal)
                                    .padding(.bottom, 30)
                            }
                        }
                    } else if isRefreshing || weatherService.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            CityPickerView { location in
                Task {
                    await updateLocation(nil)  // Clear current location
                    isUsingCurrentLocation = false  // Set to use selected city
                    locationService.locationName = location.name
                    locationService.currentLocation = location.location
                    await weatherService.updateWeather(for: location.location)
                    lastRefreshTime = Date()
                    updateTimeOfDay()
                }
            }
            .environment(\.weatherTimeOfDay, timeOfDay)
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

struct ScalingEffectModifier: ViewModifier {
    @State private var isScaling = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isScaling ? 1.05 : 1.0)
            .animation(
                Animation.easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true),
                value: isScaling
            )
            .onAppear {
                isScaling = true
            }
    }
}
