import SwiftUI
import CoreLocation
import Foundation
import WeatherKit
import EventKit

// MARK: - Weather Forecast Item View
private struct HourlyForecastItemView: View {
    let hour: Int
    let date: Date
    let temperature: Double
    let timezone: TimeZone
    
    private var hourComponent: Int {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.component(.hour, from: date)
    }
    
    private var isNight: Bool {
        hourComponent >= 18 || hourComponent < 6
    }
    
    private func formatTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(formatTime(from: date))
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
    @Binding var isDragging: Bool
    
    private let itemWidth: CGFloat = 50
    private let spacing: CGFloat = 8
    private let verticalPadding: CGFloat = 6
    private let horizontalPadding: CGFloat = 16
    
    private func createForecastItem(for forecast: WeatherService.HourlyForecast, timezone: TimeZone) -> some View {
        VStack(spacing: 6) {
            // 时间显示
            Text(formatHour(from: forecast.date, in: timezone))
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // 天气图标
            Image(forecast.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            // 温度显示
            FlipNumberView(
                value: Int(round(forecast.temperature)),
                unit: "°",
                trigger: animationTrigger
            )
            .font(.system(size: 16))
        }
        .frame(width: itemWidth)
    }
    
    private func formatHour(from date: Date, in timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer(minLength: 0)
                ZStack {
                    // 背景
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.black.opacity(0.2))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)  // 添加主阴影
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)  // 添加微弱的光晕效果
                                .blur(radius: 1)
                                .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: 0)  // 添加内部光晕
                        )
                    
                    // 滚动内容
                    ScrollView(.horizontal, showsIndicators: false) {
                        if let currentWeather = weatherService.currentWeather {
                            HStack(spacing: spacing) {
                                ForEach(Array(weatherService.hourlyForecast.prefix(24).enumerated()), id: \.1.id) { index, forecast in
                                    createForecastItem(
                                        for: forecast,
                                        timezone: currentWeather.timezone
                                    )
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                            .padding(.vertical, verticalPadding)
                            .padding(.trailing, 12)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(width: min(geometry.size.width - 32, 360), height: 115)
                Spacer(minLength: 0)
            }
        }
        .frame(height: 90)
        .padding(.bottom, 4)
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    isDragging = true
                }
                .onEnded { value in
                    isDragging = false
                }
        )
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
    @ObservedObject private var weatherService = WeatherService.shared
    
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

// MARK: - Main Weather View
struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationService = LocationService()
    @StateObject private var citySearchService = CitySearchService.shared
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingSideMenu = false
    @State private var showingLeftSide = false  // 添加左侧栏状态
    @State private var showingDailyForecast = false
    @State private var isRefreshing = false
    @State private var isLoadingWeather = false
    @State private var animationTrigger = UUID()
    @State private var isHourlyViewDragging = false
    @State private var lastRefreshTime = Date()
    @State private var isUsingCurrentLocation = false
    @AppStorage("lastSelectedLocation") private var lastSelectedLocationName: String?
    @State private var showingLocationPicker = false
    @State private var timeOfDay: WeatherTimeOfDay = .day
    @State private var dragOffset: CGFloat = 0
    @State private var showSuccessToast = false
    @State private var isDraggingUp = false
    @State private var isTouchInHourlyView = false
    @State private var sideMenuGestureEnabled = true
    @State private var errorMessage: String?
    
    private func ensureMinimumLoadingTime(startTime: Date) async {
        let timeElapsed = Date().timeIntervalSince(startTime)
        if timeElapsed < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
        }
    }
    
    private func loadInitialWeather() async {
        isLoadingWeather = true
        let startTime = Date()
        
        // 1. 尝试加载上次选择的城市
        if let lastLocationName = lastSelectedLocationName,
           let savedLocation = PresetLocation.presets.first(where: { location in
               location.name == lastLocationName
           }) {
            selectedLocation = savedLocation
            await weatherService.updateWeather(for: savedLocation.location, cityName: savedLocation.name)
            locationService.locationName = savedLocation.name
            updateTimeOfDay()
            await ensureMinimumLoadingTime(startTime: startTime)
            isLoadingWeather = false
            return
        }
        
        // 2. 尝试使用当前位置
        locationService.requestLocationPermission()
        locationService.startUpdatingLocation()
        
        // 等待位置信息（设置5秒超时）
        let locationStartTime = Date()
        while locationService.currentLocation == nil {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            if Date().timeIntervalSince(locationStartTime) > 5 {
                break
            }
        }
        
        if let currentLocation = locationService.currentLocation {
            // 使用当前位置
            await weatherService.updateWeather(for: currentLocation)
            updateTimeOfDay()
        } else {
            // 使用默认城市（上海）
            let defaultLocation = PresetLocation.presets[0]
            selectedLocation = defaultLocation
            await weatherService.updateWeather(for: defaultLocation.location, cityName: defaultLocation.name)
            locationService.locationName = defaultLocation.name
            updateTimeOfDay()
        }
        
        await ensureMinimumLoadingTime(startTime: startTime)
        isLoadingWeather = false
    }
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            let hour = Calendar.current.component(.hour, from: Date())
            timeOfDay = hour >= 18 || hour < 6 ? .night : .day
        }
    }
    
    private func refreshWeather() async {
        let startTime = Date()
        isRefreshing = true
        
        do {
            if isUsingCurrentLocation, let currentLocation = locationService.currentLocation {
                await weatherService.updateWeather(for: currentLocation)
            } else {
                await weatherService.updateWeather(for: selectedLocation.location, cityName: selectedLocation.name)
            }
            
            updateTimeOfDay()
            animationTrigger = UUID()
            showSuccessToast = true
            
            // 确保加载动画至少显示1秒
            await ensureMinimumLoadingTime(startTime: startTime)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
        lastRefreshTime = Date()
    }
    
    private func updateLocation(_ location: CLLocation?) async {
        if let location = location {
            locationService.currentLocation = location
            await weatherService.updateWeather(for: location)
        } else {
            locationService.locationName = selectedLocation.name
            locationService.currentLocation = selectedLocation.location
            await weatherService.updateWeather(for: selectedLocation.location, cityName: selectedLocation.name)
        }
        
        lastRefreshTime = Date()
        updateTimeOfDay()  // 确保在位置更新后立即更新主题
    }
    
    private func handleLocationButtonTap() async {
        // Always trigger animation when location button is tapped
        animationTrigger = UUID()
        
        // 设置位置更新回调
        locationService.onLocationUpdated = { location in
            Task {
                // 等待位置名称更新完成
                await locationService.waitForLocationNameUpdate()
                
                // 更新天气信息并触发动画
                await weatherService.updateWeather(for: location, cityName: locationService.locationName)
                lastRefreshTime = Date()
                updateTimeOfDay()
                
                // 显示定位成功的提示
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation {
                    let banner = UIBanner(title: "定位成功", subtitle: "已切换到当前位置", type: .success)
                    UIBannerPresenter.shared.show(banner)
                }
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
            await weatherService.updateWeather(for: currentLocation, cityName: locationService.locationName)
            lastRefreshTime = Date()
            updateTimeOfDay()
        }
    }
    
    private var locationButton: some View {
        Button {
            Task { @MainActor in
                await handleLocationButtonTap()
            }
        } label: {
            HStack(spacing: 4) {
                if locationService.isLocating {
                    ProgressView()
                        .scaleEffect(1.0)
                        .tint(WeatherThemeManager.shared.textColor(for: timeOfDay))
                } else if isLoadingWeather {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 18, weight: .medium))  // Increased from default size
                        .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                        .frame(width: 36, height: 36)  // Increased touch target
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 34, height: 34)  // Slightly smaller than the touch target
                        )
                }
            }
            .frame(width: 64, height: 64)
        }
        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
        .disabled(locationService.isLocating || isLoadingWeather) // 定位过程中禁用按钮
    }
    
    private var cityPickerButton: some View {
        Button {
            showingLocationPicker = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))  // Increased from default size
                .foregroundColor(.white)
                .frame(width: 36, height: 36)  // Increased touch target
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 34, height: 34)  // Slightly smaller than the touch target
                )
        }
    }
    
    private func logTimeInfo(timezone: TimeZone, hour: Int, isNight: Bool) {
        print("城市时区: \(timezone.identifier)")
        print("当地时间: \(hour)点")
        print("是否夜晚: \(isNight)")
    }
    
    private func calculateWeatherSymbol(weather: WeatherService.CurrentWeather) -> (symbolName: String, hour: Int, isNight: Bool) {
        var calendar = Calendar.current
        calendar.timeZone = weather.timezone
        let hour = calendar.component(.hour, from: weather.date)
        let isNight = hour >= 18 || hour < 6
        let symbolName = getWeatherSymbolName(for: weather.weatherCondition, isNight: isNight)
        
        return (symbolName, hour, isNight)
    }
    
    private var weatherIcon: some View {
        ZStack {
            if let weather = weatherService.currentWeather {
                let weatherInfo = calculateWeatherSymbol(weather: weather)
                Image(weatherInfo.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .offset(x: 60, y: 0)
                    .modifier(ScalingEffectModifier())
            }
        }
    }
    
    private func getWeatherSymbolName(for condition: WeatherCondition, isNight: Bool) -> String {
        switch condition {
        case .clear:
            return isNight ? "full_moon" : "sunny"
        case .cloudy:
            return isNight ? "moon_cloudy" : "cloudy"
        case .partlyCloudy, .mostlyCloudy:
            return isNight ? "partly_cloudy_night" : "partly_cloudy_daytime"
        case .drizzle:
            return "light_rain"
        case .rain:
            return "moderate_rain"
        case .heavyRain:
            return "heavy_rain"
        case .snow:
            return "light_snow"
        case .heavySnow:
            return "heavy_snow"
        case .sleet:
            return "wet"
        case .freezingDrizzle:
            return "wet"
        case .strongStorms:
            return "thunderstorm"
        case .windy:
            return "windy"
        case .foggy:
            return "fog"
        case .haze:
            return "haze"
        case .hot:
            return "high_temperature"
        case .blizzard:
            return "blizzard"
        case .blowingDust:
            return "blowing_sand"
        case .tropicalStorm:
            return "rainstorm"
        case .hurricane:
            return "typhoon"
        default:
            return isNight ? "moon_stars" : "sunny"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            BannerContainerView {
                ZStack {
                    // 背景渐变
                    WeatherBackgroundView(
                        weatherService: weatherService,
                        weatherCondition: weatherService.currentWeather?.weatherCondition.description ?? "晴天"
                    )
                    .environment(\.weatherTimeOfDay, timeOfDay)
                    
                    VStack {
                        // 前景内容
                        RefreshableView(isRefreshing: $isRefreshing) {
                            // 只在未显示预报时允许刷新
                            if !showingDailyForecast {
                                await refreshWeather()
                            }
                        } content: {
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 0)
                                    .padding(.top, -60)
                                
                                VStack(spacing: 0) {
                                    // 顶部工具栏
                                    HStack {
                                        HStack(spacing: 8) {
                                            // Location button
                                            Button(action: {
                                                Task {
                                                    if citySearchService.recentSearches.contains(where: { $0.name == locationService.locationName }) {
                                                        isLoadingWeather = true
                                                        let startTime = Date()
                                                        await handleLocationButtonTap()
                                                        let timeElapsed = Date().timeIntervalSince(startTime)
                                                        if timeElapsed < 1.0 {
                                                            try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
                                                        }
                                                        isLoadingWeather = false
                                                    }
                                                }
                                            }) {
                                                if isLoadingWeather {
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                        .tint(.white)
                                                        .frame(width: 32, height: 32)
                                                        .background(Color.white.opacity(0.2))
                                                        .clipShape(Circle())
                                                } else {
                                                    Image(systemName: "location.fill")
                                                        .font(.system(size: 18, weight: .medium))  // Increased from default size
                                                        .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
                                                        .frame(width: 36, height: 36)  // Increased touch target
                                                        .background(
                                                            Circle()
                                                                .fill(Color.white.opacity(0.15))
                                                                .frame(width: 34, height: 34)  // Slightly smaller than the touch target
                                                        )
                                                }
                                            }
                                            .disabled(locationService.isLocating || isLoadingWeather)
                                            
                                            // Add button - only show if current city is not in the list
                                            if !citySearchService.recentSearches.contains(where: { $0.name == selectedLocation.name }) {
                                                Button(action: {
                                                    citySearchService.addToRecentSearches(selectedLocation)
                                                    let generator = UINotificationFeedbackGenerator()
                                                    generator.notificationOccurred(.success)
                                                    withAnimation {
                                                        let banner = UIBanner(
                                                            title: "添加成功",
                                                            subtitle: "\(selectedLocation.name)已添加到收藏",
                                                            type: .success
                                                        )
                                                        UIBannerPresenter.shared.show(banner)
                                                    }
                                                }) {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 20, weight: .medium))  // Increased from default size
                                                        .foregroundColor(.white)
                                                        .frame(width: 36, height: 36)  // Increased touch target
                                                        .background(
                                                            Circle()
                                                                .fill(Color.white.opacity(0.15))
                                                                .frame(width: 34, height: 34)  // Slightly smaller than the touch target
                                                        )
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation(.easeInOut) {
                                                showingSideMenu.toggle()
                                            }
                                        }) {
                                            Image(systemName: "line.3.horizontal")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                    
                                    if isRefreshing || isLoadingWeather {
                                        WeatherLoadingView()
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    } else {
                                        if let weather = weatherService.currentWeather {
                                            weatherIcon
                                                .frame(maxHeight: .infinity, alignment: .top)
                                            
                                            // 天气状态气泡视图，在显示预报时隐藏
                                            WeatherContentView(
                                                weather: weather,
                                                timeOfDay: timeOfDay,
                                                locationName: isUsingCurrentLocation ? locationService.locationName : selectedLocation.name,
                                                animationTrigger: animationTrigger
                                            )
                                            .opacity(showingDailyForecast ? 0 : 1) // 添加透明度动画
                                            .animation(.easeInOut(duration: 0.3), value: showingDailyForecast) // 添加动画效果
                                            
                                            Spacer()
                                                .frame(height: 20)
                                            
                                            ScrollableHourlyForecastView(
                                                weatherService: weatherService,
                                                safeAreaInsets: geometry.safeAreaInsets,
                                                animationTrigger: animationTrigger,
                                                isDragging: $isHourlyViewDragging
                                            )
                                            .opacity(showingDailyForecast ? 0 : 1)
                                            .animation(.easeInOut(duration: 0.3), value: showingDailyForecast)
                                            .padding(.bottom, 20)
                                            .onHover { isHovered in
                                                sideMenuGestureEnabled = !isHovered
                                            }
                                            .onTapGesture { }  // 添加空手势来阻止事件传递
                                            .simultaneousGesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { _ in
                                                        sideMenuGestureEnabled = false
                                                        isHourlyViewDragging = true
                                                    }
                                                    .onEnded { _ in
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                            sideMenuGestureEnabled = true
                                                            isHourlyViewDragging = false
                                                        }
                                                    }
                                            )
                                            
                                            // 添加上拉提示
                                            VStack(spacing: 4) {
                                                Image(systemName: showingDailyForecast ? "chevron.down" : "chevron.up")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.6))
                                                Text(showingDailyForecast ? "下滑收起未来天气" : "上拉查看未来天气")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                            .padding(.top, 16)
                                            .opacity(isDraggingUp ? 0 : 1)
                                            .animation(.easeInOut(duration: 0.2), value: isDraggingUp)
                                        }
                                    }
                                }
                            }
                        }
                        .offset(y: 0)  // 移除主页面的位移
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { value in
                                    // 处理左右滑动
                                    if !isHourlyViewDragging && !showingSideMenu && !showingDailyForecast && 
                                       value.translation.width < 0 && abs(value.translation.width) > abs(value.translation.height) {
                                        withAnimation(.easeInOut) {
                                            showingSideMenu = true
                                        }
                                        return
                                    }
                                    
                                    // 处理上下滑动
                                    if showingDailyForecast && value.translation.height > 0 {
                                        // 在显示预报时，实时跟随下滑手势
                                        withAnimation(.interactiveSpring()) {
                                            dragOffset = value.translation.height
                                        }
                                        // 取消任何可能的刷新状态
                                        isRefreshing = false
                                    } else if !showingDailyForecast && value.translation.height < 0 {
                                        // 未显示预报时，实时跟随上滑手势
                                        if -value.translation.height > 50 {
                                            withAnimation(.spring()) {
                                                showingDailyForecast = true
                                            }
                                        }
                                    }
                                }
                                .onEnded { value in
                                    if showingDailyForecast && value.translation.height > 0 {
                                        // 处理下滑收起
                                        withAnimation(.spring()) {
                                            if value.translation.height > 50 {
                                                showingDailyForecast = false
                                            }
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                    }
                    
                    // 浮动气泡视图，只在有天气数据且不在加载状态时显示
                    if !showingDailyForecast && !isRefreshing && !isLoadingWeather && weatherService.currentWeather != nil {
                        FloatingBubblesView(
                            weatherService: weatherService,
                            timeOfDay: timeOfDay,
                            geometry: geometry
                        )
                    }
                    
                    // 每日预报视图
                    if showingDailyForecast {
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                // 标题
                                Text("7天预报")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                
                                DailyForecastView(forecast: weatherService.dailyForecast.map { day in
                                    DailyForecast(
                                        weekday: dayFormatter.string(from: day.date),
                                        date: day.date,
                                        temperatureMin: day.lowTemperature,
                                        temperatureMax: day.highTemperature,
                                        symbolName: day.symbolName,
                                        precipitationProbability: day.precipitationProbability
                                    )
                                })
                            }
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .ignoresSafeArea()
                            }
                            .position(x: geo.size.width / 2, y: geo.size.height * 0.65)  // 将视图定位在屏幕偏下位置
                            .offset(y: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if value.translation.height > 0 {
                                            dragOffset = value.translation.height
                                        }
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring()) {
                                            if value.translation.height > 50 {
                                                showingDailyForecast = false
                                            }
                                            dragOffset = 0
                                        }
                                    }
                            )
                        }
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                    }
                    
                    // 侧边栏菜单
                    SideMenuView(
                        isShowing: $showingSideMenu,
                        selectedLocation: $selectedLocation,
                        onLocationSelected: { location in
                            handleLocationSelection(location)
                        }
                    )
                    .animation(.easeInOut, value: showingSideMenu)
                    
                    if showingDailyForecast {
                        // 添加一个透明的视图来阻止下拉刷新
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { }  // 添加空手势以捕获触摸事件
                            .simultaneousGesture(
                                DragGesture(minimumDistance: 5)
                                    .onChanged { value in
                                        if value.translation.height > 0 {
                                            dragOffset = value.translation.height
                                        }
                                    }
                                    .onEnded { value in
                                        withAnimation(.spring()) {
                                            if value.translation.height > 50 {
                                                showingDailyForecast = false
                                            }
                                            dragOffset = 0
                                        }
                                    }
                            )
                    }

                    // 添加左侧栏视图
                    LeftSideView(isShowing: $showingLeftSide)
                        .zIndex(2)

                    // 添加边缘滑动手势识别
                    GeometryReader { geo in
                        HStack {
                            // 左边缘区域
                            Color.clear
                                .frame(width: 20)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if value.translation.width > 0 && !showingSideMenu {
                                                withAnimation {
                                                    showingLeftSide = true
                                                }
                                            }
                                        }
                                )
                            
                            Spacer()
                            
                            // 右边缘区域
                            Color.clear
                                .frame(width: 20)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if value.translation.width < 0 && !showingLeftSide {
                                                withAnimation {
                                                    showingSideMenu = true
                                                }
                                            }
                                        }
                                )
                        }
                    }
                    .allowsHitTesting(!isHourlyViewDragging)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if sideMenuGestureEnabled && !showingSideMenu && !showingDailyForecast && value.translation.width < 0 && 
                       abs(value.translation.width) > abs(value.translation.height) {
                        withAnimation(.easeInOut) {
                            showingSideMenu = true
                        }
                    }
                }
        )
        .task {
            await loadInitialWeather()
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
    
    @MainActor
    private func handleLocationSelection(_ location: PresetLocation) {
        // 开始加载
        isLoadingWeather = true
        let startTime = Date()
        
        // 使用 Task 包装异步操作
        Task {
            // 1. 更新 UI 状态
            isUsingCurrentLocation = false
            selectedLocation = location
            lastSelectedLocationName = location.name
            locationService.locationName = location.name
            
            // 2. 清除旧数据
            weatherService.clearCurrentWeather()
            
            // 3. 获取新数据
            await weatherService.updateWeather(for: location.location, cityName: location.name)
            
            // 4. 更新时间相关设置
            updateTimeOfDay()
            lastRefreshTime = Date()
            
            // 5. 确保最小加载时间
            let timeElapsed = Date().timeIntervalSince(startTime)
            if timeElapsed < 1.0 {
                try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
            }
            
            // 6. 完成加载
            isLoadingWeather = false
            
            // 7. 关闭侧边栏
            withAnimation {
                showingSideMenu = false
            }
        }
    }
    
    private let dayFormatter = DateFormatter()
    
    init() {
        dayFormatter.dateFormat = "EEE"
        dayFormatter.locale = Locale(identifier: "zh_CN")
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
