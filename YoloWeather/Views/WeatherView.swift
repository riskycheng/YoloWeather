import SwiftUI
import CoreLocation
import Foundation

// MARK: - Weather Forecast Item View
private struct HourlyForecastItemView: View {
    let hour: Int
    let date: Date
    let temperature: Double
    
    var body: some View {
        let hourString = Calendar.current.component(.hour, from: date)
        let isNight = hourString >= 18 || hourString < 6
        
        VStack(spacing: 8) {
            Text("\(hourString):00")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Image(systemName: isNight ? "moon.stars.fill" : "sun.max.fill")
                .font(.system(size: 20))
                .foregroundColor(isNight ? .purple : .yellow)
            
            Text("\(Int(round(temperature)))°")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 60)
    }
}

// MARK: - Weather Forecast ScrollView
private struct ScrollableHourlyForecastView: View {
    let weatherService: WeatherService
    let safeAreaInsets: EdgeInsets
    let animationTrigger: UUID
    
    private func formatHour(from date: Date, in timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    private func createForecastItem(for forecast: WeatherService.HourlyForecast, timezone: TimeZone) -> some View {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents(in: timezone, from: forecast.date)
        
        return VStack(spacing: 8) {
            // 时间显示
            Text(formatHour(from: forecast.date, in: timezone))
                .font(.system(size: 15))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // 天气图标 - 使用实际天气状况的图标
            Image(forecast.symbolName)  // 直接使用forecast中的symbolName，它已经包含了正确的天气状态
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            
            // 温度显示
            FlipNumberView(
                value: Int(round(forecast.temperature)),
                unit: "°",
                trigger: animationTrigger
            )
            .font(.system(size: 20))
        }
        .frame(width: 55)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    if let currentWeather = weatherService.currentWeather {
                        ForEach(Array(weatherService.hourlyForecast.prefix(24).enumerated()), id: \.1.id) { index, forecast in
                            createForecastItem(for: forecast, timezone: currentWeather.timezone)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 100)
            .background(
                Color.black.opacity(0.2)
                    .cornerRadius(15)
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height - 50)
        }
        .frame(height: 120)
        .padding(.bottom, 10)
        .padding(.horizontal)
    }
}

private struct WeatherSymbol: View {
    let symbolName: String
    
    var body: some View {
        Image(symbolName)
            .resizable()
            .scaledToFit()
    }
}

// MARK: - Weather Content View
private struct WeatherContentView: View {
    let weather: WeatherService.CurrentWeather
    let timeOfDay: WeatherTimeOfDay
    let locationName: String
    let animationTrigger: UUID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CurrentWeatherDisplayView(
                weather: weather,
                timeOfDay: timeOfDay,
                animationTrigger: animationTrigger
            )
            .scaleEffect(1.2)
            
            Text(locationName)
                .font(.system(size: 46, weight: .medium))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}

// MARK: - Floating Bubbles View
private struct FloatingBubblesView: View {
    let weatherService: WeatherService
    let timeOfDay: WeatherTimeOfDay
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            // 风速气泡
            GlassBubbleView(
                info: WeatherInfo(
                    title: "风速",
                    value: String(format: "%.1f", weatherService.currentWeather?.windSpeed ?? 0),
                    unit: "km/h"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.22, y: geometry.size.height * 0.32),
                timeOfDay: timeOfDay
            )
            
            // 降水概率气泡
            GlassBubbleView(
                info: WeatherInfo(
                    title: "降水概率",
                    value: String(format: "%.0f", (weatherService.currentWeather?.precipitationChance ?? 0) * 100),
                    unit: "%"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.32, y: geometry.size.height * 0.52),
                timeOfDay: timeOfDay
            )
            
            // 湿度气泡
            GlassBubbleView(
                info: WeatherInfo(
                    title: "湿度",
                    value: String(format: "%.0f", (weatherService.currentWeather?.humidity ?? 0) * 100),
                    unit: "%"
                ),
                initialPosition: CGPoint(x: geometry.size.width * 0.72, y: geometry.size.height * 0.42),
                timeOfDay: timeOfDay
            )
        }
    }
}

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
    @State private var animationTrigger = UUID()
    @AppStorage("showDailyForecast") private var showDailyForecast = false
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            timeOfDay = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone)
            print("TimeZone: \(weather.timezone.identifier), Theme: \(timeOfDay)")
        }
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        let refreshStartTime = Date()
        
        if isUsingCurrentLocation {
            if let location = locationService.currentLocation {
                await weatherService.updateWeather(for: location)
                updateTimeOfDay()
            }
        } else {
            if let currentLocation = locationService.currentLocation {
                await weatherService.updateWeather(for: currentLocation)
                updateTimeOfDay()
            }
        }
        
        let timeElapsed = Date().timeIntervalSince(refreshStartTime)
        if timeElapsed < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
        }
        
        lastRefreshTime = Date()
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
        updateTimeOfDay()  // 确保在位置更新后立即更新主题
    }
    
    private func handleLocationButtonTap() {
        Task {
            // Always trigger animation when location button is tapped
            animationTrigger = UUID()
            
            // 设置位置更新回调
            locationService.onLocationUpdated = { [weak locationService] location in
                Task {
                    // 等待位置名称更新完成
                    await locationService?.waitForLocationNameUpdate()
                    
                    // 更新天气信息并触发动画
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
            
            // If we already have a location, trigger an immediate refresh
            if let currentLocation = locationService.currentLocation {
                await weatherService.updateWeather(for: currentLocation)
                lastRefreshTime = Date()
                updateTimeOfDay()
            }
        }
    }
    
    private var locationButton: some View {
        Button {
            handleLocationButtonTap()
        } label: {
            HStack(spacing: 4) {
                if locationService.isLocating {
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(WeatherThemeManager.shared.textColor(for: timeOfDay))
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 32))
                }
            }
            .frame(width: 64, height: 64)
        }
        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
    }
    
    private var cityPickerButton: some View {
        Button {
            showingLocationPicker = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
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
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                WeatherBackgroundView(
                    weatherService: weatherService,
                    weatherCondition: weatherService.currentWeather?.weatherCondition.description ?? "晴天"
                )
                .environment(\.weatherTimeOfDay, timeOfDay)
                
                // 前景内容
                RefreshableView(isRefreshing: $isRefreshing) {
                    await refreshWeather()
                } content: {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 0)
                            .padding(.top, -60)
                        
                        VStack(spacing: 0) {
                            // 顶部工具栏
                            HStack {
                                locationButton
                                Spacer()
                                cityPickerButton
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            
                            if isRefreshing {
                                WeatherLoadingView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                if !isLoadingWeather {
                                    weatherIcon
                                        .frame(maxHeight: .infinity, alignment: .top)
                                }
                                
                                if let weather = weatherService.currentWeather,
                                   !isLoadingWeather {
                                    WeatherContentView(
                                        weather: weather,
                                        timeOfDay: timeOfDay,
                                        locationName: locationService.locationName,
                                        animationTrigger: animationTrigger
                                    )
                                    
                                    Spacer()
                                        .frame(height: 20)
                                }
                                
                                Spacer()
                                
                                if weatherService.currentWeather != nil && !isLoadingWeather {
                                    ScrollableHourlyForecastView(
                                        weatherService: weatherService,
                                        safeAreaInsets: geometry.safeAreaInsets,
                                        animationTrigger: animationTrigger
                                    )
                                }
                            }
                        }
                    }
                }
                
                // 浮动气泡层
                GeometryReader { geometry in
                    FloatingBubblesView(
                        weatherService: weatherService,
                        timeOfDay: timeOfDay,
                        geometry: geometry
                    )
                    .opacity(isRefreshing ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
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
}

// MARK: - View Extensions
extension View {
    func weatherRefreshable(isRefreshing: Binding<Bool>, action: @escaping () async -> Void) -> some View {
        modifier(WeatherRefreshModifier(isRefreshing: isRefreshing, action: action))
    }
}

private struct WeatherRefreshModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isRefreshing) { oldValue, newValue in
                if newValue {
                    Task {
                        await action()
                        isRefreshing = false
                    }
                }
            }
    }
}

// MARK: - Array Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
