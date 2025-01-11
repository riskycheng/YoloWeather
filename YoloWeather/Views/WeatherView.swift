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
    @State private var animationTrigger = UUID()
    @AppStorage("showDailyForecast") private var showDailyForecast = false
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            timeOfDay = WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone)
        }
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        // 添加最小延迟时间，确保动画效果可见
        let refreshStartTime = Date()
        
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
        
        // 确保刷新动画至少显示1秒
        let timeElapsed = Date().timeIntervalSince(refreshStartTime)
        if timeElapsed < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
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
    
    private var hourlyForecastView: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let leftPadding: CGFloat = 20  // 保持与其他元素相同的左边距
            let rightPadding: CGFloat = 20
            let availableWidth = totalWidth - leftPadding - rightPadding
            
            // 计算项目宽度和间距，使得每个项目有相等的左右间距
            let itemWidth: CGFloat = 55  // 固定项目宽度
            let totalItemsWidth = itemWidth * 6
            let remainingSpace = availableWidth - totalItemsWidth
            let itemSpacing = remainingSpace / 7  // 分成7份：6个项目各自左边1份，最后1份给最后项目的右边
            
            ZStack {
                Color.black.opacity(0.2)
                
                HStack(spacing: itemSpacing) {  
                    ForEach(Array(weatherService.hourlyForecast.prefix(6).enumerated()), id: \.element.id) { index, forecast in
                        VStack(spacing: 8) {
                            Text(forecast.formattedTime)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            
                            WeatherSymbol(symbolName: forecast.symbolName)
                                .frame(width: 28, height: 28)
                            
                            FlipNumberView(
                                value: Int(round(forecast.temperature)),
                                unit: "°",
                                trigger: animationTrigger
                            )
                            .font(.system(size: 20))
                        }
                        .frame(width: itemWidth)
                    }
                }
                .padding(.horizontal, itemSpacing)  // 添加与项目间距相同的左右padding
                .padding(.horizontal, leftPadding)  // 再添加与其他元素对齐的padding
            }
            .cornerRadius(15)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 100)
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
        ZStack {
            // 背景渐变
            WeatherBackgroundView(
                weatherService: weatherService,
                weatherCondition: weatherService.currentWeather?.weatherCondition.description ?? "晴天"
            )
            .environment(\.weatherTimeOfDay, timeOfDay)
            
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
                            // 天气图标
                            if !isLoadingWeather {
                                weatherIcon
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                            
                            // 城市名称和天气状况
                            if let weather = weatherService.currentWeather, !isLoadingWeather {
                                VStack(alignment: .leading, spacing: 8) {
                                    // 温度显示
                                    CurrentWeatherDisplayView(
                                        weather: weather,
                                        timeOfDay: timeOfDay,
                                        animationTrigger: animationTrigger
                                    )
                                    .scaleEffect(1.2)
                                    
                                    Text(locationService.locationName)
                                        .font(.system(size: 46, weight: .medium))
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                
                                Spacer()
                                    .frame(height: 20)
                            }
                            
                            Spacer()
                            
                            // 小时预报
                            if weatherService.currentWeather != nil && !isLoadingWeather {
                                hourlyForecastView
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 0)
                            }
                        }
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
