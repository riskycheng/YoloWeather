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

struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationService = LocationService()
    @StateObject private var citySearchService = CitySearchService.shared
    @State private var selectedLocation: PresetLocation = PresetLocation.presets[0]
    @State private var showingSideMenu = false
    @State private var showingLocationPicker = false
    @State private var isRefreshing = false
    @State private var isLoadingWeather = false
    @State private var timeOfDay: WeatherTimeOfDay = .day
    @State private var animationTrigger = UUID()
    @State private var lastRefreshTime = Date()
    @State private var isUsingCurrentLocation = false
    @AppStorage("lastSelectedLocation") private var lastSelectedLocationName: String?
    @AppStorage("showDailyForecast") private var showDailyForecast = false
    @State private var dragOffset: CGFloat = 0
    @State private var showSuccessToast = false
    
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
        print("开始刷新天气数据")
        isRefreshing = true
        defer { isRefreshing = false }
        
        let refreshStartTime = Date()
        
        // 只更新当前选中的城市天气
        if isUsingCurrentLocation {
            print("使用当前位置更新天气")
            if let currentLocation = locationService.currentLocation {
                await weatherService.updateWeather(for: currentLocation)
            }
        } else {
            print("使用选中的城市更新天气: \(selectedLocation.name)")
            print("城市坐标: 纬度 \(selectedLocation.location.coordinate.latitude), 经度 \(selectedLocation.location.coordinate.longitude)")
            await weatherService.updateWeather(for: selectedLocation.location, cityName: selectedLocation.name)
        }
        
        updateTimeOfDay()
        
        let timeElapsed = Date().timeIntervalSince(refreshStartTime)
        if timeElapsed < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
        }
        
        lastRefreshTime = Date()
    }
    
    private func updateLocation(_ location: CLLocation?) async {
        if let location = location {
            locationService.currentLocation = location
            await weatherService.updateWeather(for: location)
        } else {
            locationService.locationName = selectedLocation.name
            locationService.currentLocation = selectedLocation.location
            await weatherService.updateWeather(for: selectedLocation.location)
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
                await weatherService.updateWeather(for: location)
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
            await weatherService.updateWeather(for: currentLocation)
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
                } else {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 32))
                }
            }
            .frame(width: 64, height: 64)
        }
        .foregroundStyle(WeatherThemeManager.shared.textColor(for: timeOfDay))
        .disabled(locationService.isLocating) // 定位过程中禁用按钮
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
        let symbolName = getWeatherSymbolName(for: weather.weatherCondition, isNight: isNight)
        
        // 使用 selectedLocation 的名称，因为这是用户当前选择的城市
        let cityName = isUsingCurrentLocation ? locationService.locationName : selectedLocation.name
        
        print("天气图标计算 - 城市: \(cityName)")
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
    
    var addButton: some View {
        Button(action: {
            if !citySearchService.recentSearches.contains(where: { $0.name == selectedLocation.name }) {
                // 如果当前城市不在收藏列表中，则添加到收藏
                citySearchService.addToRecentSearches(selectedLocation)
                // 显示添加成功提示
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation {
                    let banner = UIBanner(title: "添加成功", subtitle: "\(selectedLocation.name)已添加到收藏", type: .success)
                    UIBannerPresenter.shared.show(banner)
                }
            } else {
                // 如果当前城市已在收藏列表中，则触发定位功能
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation {
                    let banner = UIBanner(title: "定位中", subtitle: "正在获取当前位置...", type: .info)
                    UIBannerPresenter.shared.show(banner)
                }
                
                // 使用Task包装异步调用
                Task { @MainActor in
                    // 请求定位权限
                    locationService.requestLocationPermission()
                    
                    // 开始更新位置
                    locationService.startUpdatingLocation()
                    
                    // 设置为使用当前位置
                    isUsingCurrentLocation = true
                    
                    // 设置位置更新回调
                    locationService.onLocationUpdated = { location in
                        Task { @MainActor in
                            // 等待位置名称更新完成
                            await locationService.waitForLocationNameUpdate()
                            
                            // 更新天气信息并触发动画
                            await weatherService.updateWeather(for: location)
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
                    
                    // If we already have a location, trigger an immediate refresh
                    if let currentLocation = locationService.currentLocation {
                        await weatherService.updateWeather(for: currentLocation)
                        lastRefreshTime = Date()
                        updateTimeOfDay()
                    }
                }
            }
        }) {
            Image(systemName: citySearchService.recentSearches.contains(where: { $0.name == selectedLocation.name }) ? "location.circle.fill" : "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .overlay {
                    if locationService.isLocating {
                        ProgressView()
                            .tint(.white)
                    }
                }
        }
        .disabled(locationService.isLocating) // 定位过程中禁用按钮
    }
    
    var topLeftButton: some View {
        Button(action: {
            Task {
                if citySearchService.recentSearches.contains(where: { $0.name == locationService.locationName }) {
                    // 如果城市已在收藏列表中,则作为定位按钮使用
                    isLoadingWeather = true  // 开始加载
                    let startTime = Date()
                    
                    await handleLocationButtonTap()
                    
                    // 确保最小加载时间
                    let timeElapsed = Date().timeIntervalSince(startTime)
                    if timeElapsed < 1.0 {
                        try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
                    }
                    
                    isLoadingWeather = false  // 结束加载
                } else {
                    // 如果城市不在收藏列表中,添加到收藏
                    let currentLocation = PresetLocation(
                        name: locationService.locationName,
                        location: locationService.currentLocation ?? CLLocation(latitude: 0, longitude: 0)
                    )
                    citySearchService.addToRecentSearches(currentLocation)
                    
                    // 显示成功提示
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    withAnimation {
                        let banner = UIBanner(
                            title: "添加成功",
                            subtitle: "\(locationService.locationName)已添加到收藏",
                            type: .success
                        )
                        UIBannerPresenter.shared.show(banner)
                    }
                }
            }
        }) {
            Image(systemName: citySearchService.recentSearches.contains(where: { $0.name == locationService.locationName }) 
                ? "location.circle.fill" 
                : "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
        .disabled(locationService.isLocating)
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
                                    topLeftButton
                                    
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
                                            locationName: isUsingCurrentLocation ? locationService.locationName : selectedLocation.name,
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
                        handleLocationSelection(location)
                    }
                    .animation(.easeInOut, value: showingSideMenu)
                    
                    // 成功提示
                    if showSuccessToast {
                        VStack {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 20))
                                Text("\(selectedLocation.name)已添加到收藏")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(25)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, 100)
                    }
                }
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
    
    @MainActor
    private func handleLocationSelection(_ location: PresetLocation) {
        print("主视图 - 选择城市: \(location.name)")
        print("主视图 - 城市坐标: 纬度 \(location.location.coordinate.latitude), 经度 \(location.location.coordinate.longitude)")
        
        // 开始加载
        isLoadingWeather = true
        let startTime = Date()
        
        // 使用 Task 包装异步操作
        Task {
            print("主视图 - 正在使用 WeatherService 获取天气数据...")
            
            // 1. 更新 UI 状态
            isUsingCurrentLocation = false
            selectedLocation = location
            lastSelectedLocationName = location.name
            locationService.locationName = location.name
            
            // 2. 清除旧数据
            weatherService.clearCurrentWeather()
            
            // 3. 获取新数据
            await weatherService.updateWeather(for: location.location, cityName: location.name)
            print("主视图 - 天气数据更新完成")
            
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
