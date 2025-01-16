import SwiftUI
import CoreLocation
import Foundation
import WeatherKit

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
    @State private var isLoadingWeather = true
    @State private var animationTrigger = UUID()
    @State private var showingSideMenu = false
    @AppStorage("lastSelectedLocation") private var lastSelectedLocationName: String?
    @AppStorage("showDailyForecast") private var showDailyForecast = false
    @State private var dragOffset: CGFloat = 0
    
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
            await weatherService.updateWeather(for: savedLocation.location)
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
            isUsingCurrentLocation = true
            await weatherService.updateWeather(for: currentLocation)
            updateTimeOfDay()
        } else {
            // 使用默认城市（上海）
            let defaultLocation = PresetLocation.presets[0]
            selectedLocation = defaultLocation
            await weatherService.updateWeather(for: defaultLocation.location)
            locationService.locationName = defaultLocation.name
            updateTimeOfDay()
        }
        
        await ensureMinimumLoadingTime(startTime: startTime)
        isLoadingWeather = false
    }
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            var calendar = Calendar.current
            calendar.timeZone = weather.timezone
            
            let hour = calendar.component(.hour, from: Date())
            let date = Date()
            
            // 创建格式化器显示完整时间
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = weather.timezone
            
            timeOfDay = (hour >= 18 || hour < 6) ? .night : .day
            print("城市: \(locationService.locationName)")
            print("当前UTC时间: \(formatter.string(from: date))")
            print("时区: \(weather.timezone.identifier) (偏移: \(weather.timezone.secondsFromGMT()/3600)小时)")
            print("当地时间: \(formatter.string(from: date))")
            print("小时数: \(hour), 主题: \(timeOfDay)")
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
        let symbolName = getWeatherSymbolName(condition: weather.weatherCondition, isNight: isNight)
        
        print("天气图标计算 - 城市: \(locationService.locationName)")
        print("天气图标计算 - 当地时间: \(hour)点")
        print("天气图标计算 - 是否夜晚: \(isNight)")
        print("天气图标计算 - 天气状况: \(weather.weatherCondition)")
        print("天气图标计算 - 选择的图标: \(symbolName)")
        
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
                    .onAppear {
                        print("城市时区: \(weather.timezone.identifier)")
                        print("当地时间: \(weatherInfo.hour)点")
                        print("是否夜晚: \(weatherInfo.isNight)")
                        print("选择的图标: \(weatherInfo.symbolName)")
                    }
            }
        }
    }
    
    private func getWeatherSymbolName(condition: WeatherCondition, isNight: Bool) -> String {
        switch condition {
        case .clear, .mostlyClear, .hot:
            return isNight ? "moon" : "sunny"
        case .cloudy:
            return isNight ? "cloudy_night" : "cloudy"
        case .mostlyCloudy, .partlyCloudy:
            return isNight ? "partly_cloudy_night" : "partly_cloudy_daytime"
        case .drizzle, .rain:
            return "moderate_rain"
        case .snow, .heavySnow, .blizzard:
            return "heavy_snow"
        default:
            return isNight ? "moon" : "sunny"
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
                                cityPickerButton
                                
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
                                    
                                    WeatherContentView(
                                        weather: weather,
                                        timeOfDay: timeOfDay,
                                        locationName: locationService.locationName,
                                        animationTrigger: animationTrigger
                                    )
                                    
                                    Spacer()
                                        .frame(height: 20)
                                    
                                    Spacer()
                                        .frame(minHeight: 0, maxHeight: .infinity)
                                        .frame(height: 20)
                                    
                                    ScrollableHourlyForecastView(
                                        weatherService: weatherService,
                                        safeAreaInsets: geometry.safeAreaInsets,
                                        animationTrigger: animationTrigger
                                    )
                                    .padding(.bottom, 20)
                                }
                            }
                        }
                    }
                }
                
                // 添加一个透明的边缘手势检测视图
                Color.clear
                    .frame(width: 20)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 20)
                            .onChanged { gesture in
                                let translation = gesture.translation.width
                                // 只在首次触发时打印日志
                                if translation < -20 && !showingSideMenu {
                                    print("触发右边缘滑动手势")
                                    withAnimation(.easeInOut) {
                                        showingSideMenu = true
                                    }
                                }
                            }
                    )
                
                // 浮动气泡层
                GeometryReader { geometry in
                    FloatingBubblesView(
                        weatherService: weatherService,
                        timeOfDay: timeOfDay,
                        geometry: geometry
                    )
                    .opacity(isRefreshing || isLoadingWeather ? 0 : 1)
                    .animation(.easeInOut(duration: 0.3), value: isRefreshing)
                    .animation(.easeInOut(duration: 0.3), value: isLoadingWeather)
                }
                
                // 侧边栏菜单
                SideMenuView(
                    isShowing: $showingSideMenu,
                    selectedLocation: $selectedLocation,
                    locations: PresetLocation.presets
                ) { location in
                    Task {
                        isLoadingWeather = true
                        let startTime = Date()
                        lastSelectedLocationName = location.name
                        isUsingCurrentLocation = false
                        await weatherService.updateWeather(for: location.location)
                        locationService.locationName = location.name
                        updateTimeOfDay()
                        await ensureMinimumLoadingTime(startTime: startTime)
                        isLoadingWeather = false
                    }
                }
                .animation(.easeInOut, value: showingSideMenu)
            }
        }
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
