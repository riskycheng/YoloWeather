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
    @State private var isLoadingWeather = false
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
            // 设置位置更新回调
            locationService.onLocationUpdated = { [weak locationService] location in
                Task {
                    // 等待位置名称更新完成
                    await locationService?.waitForLocationNameUpdate()
                    
                    // 更新天气信息
                    await weatherService.updateWeather(for: location)
                    lastRefreshTime = Date()
                    updateTimeOfDay()
                }
            }
            
            // 请求定位权限
            locationService.requestLocationPermission()
            
            // 开始更新位置
            locationService.startUpdatingLocation()
            
            // 设置为使用当前位置
            isUsingCurrentLocation = true
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
                        
                        FlipNumberView(
                            value: Int(round(forecast.temperature)),
                            unit: "°"
                        )
                        .font(.system(size: 20))
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
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
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
                    .offset(x: 60, y: 0)
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
                VStack(spacing: 0) {
                    // 顶部工具栏
                    HStack {
                        locationButton
                        Spacer()
                        cityPickerButton
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    
                    // 天气图标
                    if !isLoadingWeather {
                        weatherIcon
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                    
                    // 城市名称和天气状况
                    if let weather = weatherService.currentWeather, !isLoadingWeather {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(locationService.locationName ?? "未知位置")
                                .font(.system(size: 34, weight: .medium))
                            Text(weather.condition)
                                .font(.system(size: 17))
                                .opacity(0.8)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        
                        // 温度显示
                        FlipNumberView(
                            value: Int(round(weather.temperature)),
                            unit: "°"
                        )
                        .font(.system(size: 96, weight: .thin))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .padding(.top, -10)
                    } else {
                        // Loading indicator when weather is not available or refreshing
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // 小时预报
                    if weatherService.currentWeather != nil && !isLoadingWeather {
                        hourlyForecastView
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(
                selectedLocation: $selectedLocation,
                locationService: locationService,
                isUsingCurrentLocation: $isUsingCurrentLocation,
                onLocationSelected: { location in
                    Task {
                        await updateLocation(location)
                    }
                }
            )
        }
        .task {
            // Request location permission and start updating location
            locationService.requestLocationPermission()
            locationService.startUpdatingLocation()
            
            // Wait for location to be available (with timeout)
            let startTime = Date()
            while locationService.currentLocation == nil {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                if Date().timeIntervalSince(startTime) > 5 {
                    // Timeout after 5 seconds, use default location
                    await updateLocation(selectedLocation.location)
                    return
                }
            }
            
            // Use current location if available
            if let location = locationService.currentLocation {
                isUsingCurrentLocation = true
                await updateLocation(location)
            } else {
                // Fallback to default location
                await updateLocation(selectedLocation.location)
            }
        }
        .onChange(of: selectedLocation) { oldValue, newValue in
            // When city changes, update weather for the new city
            Task {
                isLoadingWeather = true
                isUsingCurrentLocation = false
                locationService.locationName = newValue.name
                locationService.currentLocation = newValue.location
                await weatherService.updateWeather(for: newValue.location)
                lastRefreshTime = Date()
                updateTimeOfDay()
                isLoadingWeather = false
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
