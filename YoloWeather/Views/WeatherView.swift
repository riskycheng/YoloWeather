// MARK: - Time of Day Manager
class TimeOfDayManager: ObservableObject {
    @Published var timeOfDay: WeatherTimeOfDay = .day
    
    init() {
        NotificationCenter.default.addObserver(
            forName: .updateWeatherTimeOfDay,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let timeOfDay = notification.value as? WeatherTimeOfDay {
                withAnimation {
                    self?.timeOfDay = timeOfDay
                }
            }
        }
    }
}

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
    @ObservedObject private var locationService = LocationService.shared
    
    private var coordinateText: String {
        if locationName == "定位中..." {
            return "正在获取位置信息..."
        }
        guard let location = locationService.currentLocation else { return "" }
        return String(format: "%.4f, %.4f", location.coordinate.latitude, location.coordinate.longitude)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CurrentWeatherDisplayView(
                weather: weather,
                timeOfDay: timeOfDay,
                animationTrigger: animationTrigger
            )
            .scaleEffect(1.2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(locationName)
                    .font(.system(size: 46, weight: .medium))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                
                Text(coordinateText)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
    }
}

// MARK: - Main Weather View
struct WeatherView: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var locationService = LocationService.shared
    @StateObject private var citySearchService = CitySearchService.shared
    @StateObject private var timeOfDayManager = TimeOfDayManager()
    @State private var selectedLocation: PresetLocation = PresetLocation(
        name: "定位中...",
        location: CLLocation(latitude: 0, longitude: 0)
    ) {
        didSet {
            Task {
                isLoadingWeather = true
                
                // 清除当前天气数据
                weatherService.clearCurrentWeather()
                
                // 先设置 weatherService.currentCityName，确保与 selectedLocation.name 一致
                weatherService.setCurrentCityName(selectedLocation.name)
                
                // 使用新选择的城市更新天气
                await weatherService.updateWeather(
                    for: selectedLocation.location,
                    cityName: selectedLocation.name
                )
                
                // 再次确保 weatherService.currentCityName 与 selectedLocation.name 一致
                if weatherService.currentCityName != selectedLocation.name {
                    print("警告：weatherService.currentCityName (\(weatherService.currentCityName ?? "nil")) 与 selectedLocation.name (\(selectedLocation.name)) 不一致，强制更新")
                    weatherService.setCurrentCityName(selectedLocation.name)
                }
                
                // 更新相关状态
                isLoadingWeather = false
                lastRefreshTime = Date()
                
                // 触发 UI 刷新
                animationTrigger = UUID()
            }
        }
    }
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
    @State private var dragOffset: CGFloat = 0
    @State private var showSuccessToast = false
    @State private var isDraggingUp = false
    @State private var isTouchInHourlyView = false
    @State private var sideMenuGestureEnabled = true
    @State private var errorMessage: String?
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLeftSideActive = false
    
    private var timeOfDay: WeatherTimeOfDay {
        timeOfDayManager.timeOfDay
    }
    
    private func ensureMinimumLoadingTime(startTime: Date) async {
        let timeElapsed = Date().timeIntervalSince(startTime)
        if timeElapsed < 1.0 {
            try? await Task.sleep(nanoseconds: UInt64((1.0 - timeElapsed) * 1_000_000_000))
        }
    }
    
    private func loadInitialWeather() async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        
        print("开始加载初始天气数据...")
        
        // 清除 weatherService 的当前城市名称
        weatherService.clearCurrentWeather()
        weatherService.setCurrentCityName("")
        
        // 1. 首先尝试获取当前位置
        locationService.startUpdatingLocation()
        
        // 等待获取位置（最多15秒，增加超时时间以确保有足够的时间获取位置）
        let startTime = Date()
        while locationService.currentLocation == nil {
            if Date().timeIntervalSince(startTime) > 15 {
                print("等待位置超时，继续尝试获取位置")
                // 不再使用默认城市，而是继续尝试获取位置
                break
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 等待0.5秒
        }
        
        if let currentLocation = locationService.currentLocation {
            print("成功获取当前位置：\(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
            
            // 使用地理编码器获取城市名称
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(currentLocation)
                if let placemark = placemarks.first,
                   let city = placemark.locality ?? placemark.administrativeArea {
                    print("地理编码成功，当前城市：\(city)")
                    
                    // 查找匹配的预设城市
                    if let matchedCity = PresetLocation.presets.first(where: { $0.name == city || 
                                                                             ($0.name.contains(city) && city.count > 1) || 
                                                                             (city.contains($0.name) && $0.name.count > 1) }) {
                        print("找到匹配的预设城市：\(matchedCity.name)")
                        await switchToCity(matchedCity)
                        return
                    }
                    
                    // 如果没有匹配的预设城市，创建一个新的
                    print("未找到匹配的预设城市，创建新的位置：\(city)")
                    let newLocation = PresetLocation(
                        name: city,
                        location: currentLocation
                    )
                    await switchToCity(newLocation)
                    return
                }
            } catch {
                print("地理编码失败: \(error.localizedDescription)")
            }
        } else {
            print("未能获取当前位置，继续尝试...")
            // 不再使用默认城市，而是显示"定位中..."
            // 此时 selectedLocation 已经是初始化时设置的"定位中..."状态
        }
    }
    
    // 切换到指定城市并更新所有相关视图
    private func switchToCity(_ city: PresetLocation) async {
        print("\n=== 开始切换到城市：\(city.name) ===")
        print("当前选中城市：\(selectedLocation.name)")
        
        // 更新选中的城市
        selectedLocation = city
        isUsingCurrentLocation = true
        
        // 不再保存上次选择的城市
        // lastSelectedLocationName = city.name
        
        // 更新位置服务中的城市信息
        locationService.currentCity = city.name
        locationService.currentLocation = city.location
        
        // 清除当前天气数据
        weatherService.clearCurrentWeather()
        
        // 先设置 weatherService.currentCityName，确保与 selectedLocation.name 一致
        weatherService.setCurrentCityName(city.name)
        
        // 获取新的天气数据
        await weatherService.updateWeather(
            for: city.location,
            cityName: city.name
        )
        
        // 再次确保 weatherService.currentCityName 与 selectedLocation.name 一致
        if weatherService.currentCityName != city.name {
            print("警告：weatherService.currentCityName (\(weatherService.currentCityName ?? "nil")) 与 selectedLocation.name (\(city.name)) 不一致，强制更新")
            weatherService.setCurrentCityName(city.name)
            
            // 重新获取天气数据
            await weatherService.updateWeather(
                for: city.location,
                cityName: city.name
            )
        }
        
        // 触发动画更新
        animationTrigger = UUID()
        
        // 更新时间相关设置
        updateTimeOfDay()
        
        // 确保在主线程更新 UI
        await MainActor.run {
            // 再次确认选中的城市已更新
            if selectedLocation.name != city.name {
                print("警告：选中城市未正确更新，强制更新为：\(city.name)")
                selectedLocation = city
            }
            
            // 再次确认 weatherService.currentCityName 已更新
            if weatherService.currentCityName != city.name {
                print("警告：weatherService.currentCityName 未正确更新，强制更新为：\(city.name)")
                weatherService.setCurrentCityName(city.name)
            }
        }
        
        // 打印日志
        if let currentWeather = weatherService.currentWeather {
            print("\n=== 已切换到城市: \(city.name) ===")
            print("当前温度: \(Int(round(currentWeather.temperature)))°")
            print("天气状况: \(currentWeather.condition)")
            print("最高温度: \(Int(round(currentWeather.highTemperature)))°")
            print("最低温度: \(Int(round(currentWeather.lowTemperature)))°")
            print("UI 显示城市: \(selectedLocation.name)")
            print("WeatherService 城市名称: \(weatherService.currentCityName ?? "nil")")
        } else {
            print("\n=== 警告：切换到城市 \(city.name) 后未能获取天气数据 ===")
        }
    }
    
    private func refreshWeather() async {
        let startTime = Date()
        isRefreshing = true
        
        do {
            // 获取当前选中城市的坐标
            let location = CLLocation(
                latitude: selectedLocation.latitude,
                longitude: selectedLocation.longitude
            )
            
            // 确保 weatherService.currentCityName 与 selectedLocation.name 一致
            if weatherService.currentCityName != selectedLocation.name {
                print("刷新前发现 weatherService.currentCityName (\(weatherService.currentCityName ?? "nil")) 与 selectedLocation.name (\(selectedLocation.name)) 不一致，强制更新")
                weatherService.setCurrentCityName(selectedLocation.name)
            }
            
            // 更新天气数据，使用当前选中的城市，而不是当前地理位置
            print("刷新当前选中城市：\(selectedLocation.name) 的天气数据")
            await weatherService.updateWeather(
                for: location,
                cityName: selectedLocation.name
            )
            
            // 确保刷新动画至少显示1秒
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime < 1.0 {
                try? await Task.sleep(nanoseconds: UInt64((1.0 - elapsedTime) * 1_000_000_000))
            }
            
            // 更新最后刷新时间
            lastRefreshTime = Date()
            
            // 触发 UI 刷新
            animationTrigger = UUID()
            
            print("已完成刷新城市：\(selectedLocation.name) 的天气数据")
        } catch {
            print("刷新天气失败: \(error)")
        }
        
        isRefreshing = false
    }
    
    private func updateTimeOfDay() {
        if let weather = weatherService.currentWeather {
            var calendar = Calendar.current
            calendar.timeZone = weather.timezone
            let hour = calendar.component(.hour, from: Date())
            let newTimeOfDay: WeatherTimeOfDay = (hour >= 6 && hour < 18) ? .day : .night
            
            // 只在主题实际变化时更新
            if timeOfDayManager.timeOfDay != newTimeOfDay {
                timeOfDayManager.timeOfDay = newTimeOfDay
                
                print("\n=== 更新时间主题 ===")
                print("城市时区：\(weather.timezone.identifier)")
                print("当地时间：\(hour)点")
                print("使用主题：\(newTimeOfDay == .day ? "白天" : "夜晚")")
            }
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
        let hour = calendar.component(.hour, from: Date())
        let isNight = hour < 6 || hour >= 18
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
                                print("下拉刷新触发，刷新当前选中城市：\(selectedLocation.name)")
                                // 只刷新当前选中的城市，不触发位置更新
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
                                        LocationButton(timeOfDayManager: timeOfDayManager, selectedLocation: $selectedLocation, animationTrigger: $animationTrigger)
                                            .frame(width: 44, height: 44)
                                        
                                        // 添加收藏按钮
                                        if !citySearchService.recentSearches.contains(selectedLocation) {
                                            Button {
                                                withAnimation {
                                                    citySearchService.addToRecentSearches(selectedLocation)
                                                    // 显示成功提示
                                                    showSuccessToast = true
                                                    // 3秒后隐藏提示
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                        withAnimation {
                                                            showSuccessToast = false
                                                        }
                                                    }
                                                }
                                            } label: {
                                                toolbarButton("plus.circle.fill")
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation {
                                                showingSideMenu = true
                                            }
                                        } label: {
                                            toolbarButton("line.3.horizontal")
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                                    .overlay(alignment: .top) {
                                        if showSuccessToast {
                                            Text("已添加到收藏")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(
                                                    Capsule()
                                                        .fill(.black.opacity(0.6))
                                                )
                                                .transition(.move(edge: .top).combined(with: .opacity))
                                                .offset(y: 50)
                                        }
                                    }
                                    
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
                                                locationName: selectedLocation.name,
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
                                        dragOffset = value.translation.height
                                        // 取消任何可能的刷新状态
                                        isRefreshing = false
                                    } else if !showingDailyForecast && value.translation.height < 0 {
                                        // 未显示预报时，实时跟随上滑手势
                                        if -value.translation.height > 50 {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                isDraggingUp = true
                                            }
                                        }
                                    }
                                }
                                .onEnded { value in
                                    if showingDailyForecast {
                                        // 处理下滑结束
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                            if value.translation.height > 100 {
                                                showingDailyForecast = false
                                                dragOffset = 0
                                            } else {
                                                dragOffset = 0
                                            }
                                        }
                                    } else {
                                        // 处理上滑结束
                                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                            if -value.translation.height > 100 {
                                                showingDailyForecast = true
                                            }
                                            isDraggingUp = false
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
                                Text("10天预报")
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
                    LeftSideView(isShowing: $showingLeftSide, selectedLocation: $selectedLocation)
                        .zIndex(2)
                        .onChange(of: showingLeftSide) { newValue in
                            isLeftSideActive = newValue
                        }

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
                                            if value.translation.width > 0 && !showingSideMenu && !showingDailyForecast {
                                                withAnimation {
                                                    showingLeftSide = true
                                                    isLeftSideActive = true
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
                                            if value.translation.width < 0 && !showingLeftSide && !isLeftSideActive {
                                                withAnimation {
                                                    showingSideMenu = true
                                                }
                                            }
                                        }
                                )
                        }
                    }
                    .allowsHitTesting(!isHourlyViewDragging && !isLeftSideActive)
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if sideMenuGestureEnabled && !showingSideMenu && !showingDailyForecast && !isLeftSideActive && 
                       value.translation.width < 0 && abs(value.translation.width) > abs(value.translation.height) {
                        withAnimation(.easeInOut) {
                            showingSideMenu = true
                        }
                    }
                }
        )
        .task {
            // 应用启动时，始终尝试获取当前位置
            locationService.startUpdatingLocation()
            
            // 如果当前是"定位中..."状态，则尝试获取当前位置并切换城市
            if selectedLocation.name == "定位中..." {
                print("应用启动，当前是'定位中...'状态，尝试获取当前位置")
                
                // 清除上次选择的城市记录
                lastSelectedLocationName = nil
                UserDefaults.standard.removeObject(forKey: "LastSelectedCity")
                
                // 加载初始天气数据
                await loadInitialWeather()
                
                // 如果 15 秒后仍然没有获取到位置，继续尝试
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if selectedLocation.name == "定位中..." && locationService.currentLocation != nil {
                    print("初始化后仍未切换城市，尝试再次处理位置更新")
                    await handleLocationUpdate()
                }
            } else {
                // 如果已经有选中的城市，则只刷新当前选中的城市
                print("应用启动，刷新当前选中城市：\(selectedLocation.name) 的天气数据")
                await refreshWeather()
            }
            
            // 强制刷新 UI
            forceRefreshUI()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    // 应用进入前台时，始终尝试获取当前位置
                    locationService.startUpdatingLocation()
                    
                    // 如果当前是"定位中..."状态，则尝试获取当前位置并切换城市
                    if selectedLocation.name == "定位中..." {
                        print("应用进入前台，当前是'定位中...'状态，尝试获取当前位置")
                        
                        // 清除上次选择的城市记录
                        lastSelectedLocationName = nil
                        UserDefaults.standard.removeObject(forKey: "LastSelectedCity")
                        
                        // 清除 weatherService 的当前城市名称
                        weatherService.clearCurrentWeather()
                        weatherService.setCurrentCityName("")
                        
                        // 重新加载天气数据
                        await loadInitialWeather()
                        
                        // 如果 5 秒后仍然没有获取到位置，继续尝试
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if selectedLocation.name == "定位中..." && locationService.currentLocation != nil {
                            print("进入前台后仍未切换城市，尝试再次处理位置更新")
                            await handleLocationUpdate()
                        }
                    } else {
                        // 如果已经有选中的城市，则只刷新当前选中的城市
                        print("应用进入前台，刷新当前选中城市：\(selectedLocation.name) 的天气数据")
                        
                        // 如果上次刷新时间超过 5 分钟，则刷新天气数据
                        if Date().timeIntervalSince(lastRefreshTime) > 300 {
                            await refreshWeather()
                        }
                    }
                }
            }
        }
        .onAppear {
            // 在视图出现时设置通知观察者
            // 先移除之前可能存在的观察者，避免重复添加
            NotificationCenter.default.removeObserver(
                self,
                name: LocationService.locationUpdatedNotification,
                object: nil
            )
            
            print("添加位置更新通知观察者")
            NotificationCenter.default.addObserver(
                forName: LocationService.locationUpdatedNotification,
                object: nil,
                queue: .main
            ) { notification in
                // 当位置更新时，尝试切换到当前城市
                print("收到位置更新通知，准备处理...")
                Task {
                    await self.handleLocationUpdate()
                }
            }
        }
        .onDisappear {
            // 在视图消失时移除通知观察者
            NotificationCenter.default.removeObserver(
                self,
                name: LocationService.locationUpdatedNotification,
                object: nil
            )
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
            
            // 不再保存上次选择的城市
            // lastSelectedLocationName = location.name
            
            locationService.currentCity = location.name
            locationService.currentLocation = location.location
            
            // 2. 清除旧数据
            weatherService.clearCurrentWeather()
            
            // 3. 先设置 weatherService.currentCityName，确保与 selectedLocation.name 一致
            weatherService.setCurrentCityName(location.name)
            
            // 4. 获取新数据
            await weatherService.updateWeather(
                for: location.location,
                cityName: location.name
            )
            
            // 5. 再次确保 weatherService.currentCityName 与 selectedLocation.name 一致
            if weatherService.currentCityName != location.name {
                print("警告：weatherService.currentCityName (\(weatherService.currentCityName ?? "nil")) 与 selectedLocation.name (\(location.name)) 不一致，强制更新")
                weatherService.setCurrentCityName(location.name)
                
                // 重新获取天气数据
                await weatherService.updateWeather(
                    for: location.location,
                    cityName: location.name
                )
            }
            
            // 6. 更新时间相关设置
            updateTimeOfDay()
            lastRefreshTime = Date()
            
            // 7. 确保最小加载时间
            await ensureMinimumLoadingTime(startTime: startTime)
            
            // 8. 触发动画更新
            animationTrigger = UUID()
            
            // 9. 完成加载
            isLoadingWeather = false
            
            // 10. 关闭侧边栏
            withAnimation {
                showingSideMenu = false
            }
            
            // 11. 打印日志以便调试
            if let currentWeather = weatherService.currentWeather {
                print("\n=== 已切换到城市: \(location.name) ===")
                print("当前温度: \(Int(round(currentWeather.temperature)))°")
                print("天气状况: \(currentWeather.condition)")
                print("最高温度: \(Int(round(currentWeather.highTemperature)))°")
                print("最低温度: \(Int(round(currentWeather.lowTemperature)))°")
                print("WeatherService 城市名称: \(weatherService.currentCityName ?? "nil")")
            } else {
                print("\n=== 警告：切换到城市 \(location.name) 后未能获取天气数据 ===")
            }
        }
    }
    
    private let dayFormatter = DateFormatter()
    
    init() {
        dayFormatter.dateFormat = "EEE"
        dayFormatter.locale = Locale(identifier: "zh_CN")
    }
    
    // 处理位置更新
    private func handleLocationUpdate() async {
        print("\n=== 收到位置更新通知，尝试切换到当前城市 ===")
        print("当前选中城市：\(selectedLocation.name)")
        print("WeatherService 城市名称：\(weatherService.currentCityName ?? "nil")")
        
        // 如果当前正在加载天气，则跳过
        guard !isLoadingWeather else {
            print("正在加载天气，跳过位置更新处理")
            return
        }
        
        // 如果没有位置信息，则跳过
        guard let currentLocation = locationService.currentLocation else {
            print("没有位置信息，跳过位置更新处理")
            return
        }
        
        print("当前位置坐标：\(currentLocation.coordinate.latitude), \(currentLocation.coordinate.longitude)")
        
        // 使用地理编码器获取城市名称
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(currentLocation)
            if let placemark = placemarks.first,
               let city = placemark.locality ?? placemark.administrativeArea {
                print("地理编码成功，当前城市：\(city)")
                
                // 如果当前是"定位中..."状态，或者城市已经变化，则切换城市
                if selectedLocation.name == "定位中..." || 
                   !(selectedLocation.name == city || 
                     (selectedLocation.name.contains(city) && city.count > 1) || 
                     (city.contains(selectedLocation.name) && selectedLocation.name.count > 1)) {
                    
                    print("需要切换城市：从 \(selectedLocation.name) 切换到 \(city)")
                    
                    // 查找匹配的预设城市
                    if let matchedCity = PresetLocation.presets.first(where: { $0.name == city || 
                                                                              ($0.name.contains(city) && city.count > 1) || 
                                                                              (city.contains($0.name) && $0.name.count > 1) }) {
                        print("找到匹配的预设城市：\(matchedCity.name)，切换中...")
                        
                        // 清除当前天气数据
                        weatherService.clearCurrentWeather()
                        weatherService.setCurrentCityName("")
                        
                        await switchToCity(matchedCity)
                        
                        // 检查切换后的状态
                        print("切换后的选中城市：\(selectedLocation.name)")
                        print("切换后的 WeatherService 城市名称：\(weatherService.currentCityName ?? "nil")")
                        
                        // 强制刷新 UI
                        await MainActor.run {
                            animationTrigger = UUID()
                        }
                        
                        return
                    }
                    
                    // 如果没有匹配的预设城市，创建一个新的
                    print("未找到匹配的预设城市，创建新的位置：\(city)")
                    
                    // 清除当前天气数据
                    weatherService.clearCurrentWeather()
                    weatherService.setCurrentCityName("")
                    
                    let newLocation = PresetLocation(
                        name: city,
                        location: currentLocation
                    )
                    await switchToCity(newLocation)
                    
                    // 检查切换后的状态
                    print("切换后的选中城市：\(selectedLocation.name)")
                    print("切换后的 WeatherService 城市名称：\(weatherService.currentCityName ?? "nil")")
                    
                    // 强制刷新 UI
                    await MainActor.run {
                        animationTrigger = UUID()
                    }
                    
                    return
                }
                
                // 如果当前已经是这个城市，则确保 weatherService.currentCityName 与 selectedLocation.name 一致
                print("当前已经是城市：\(city)，跳过切换")
                
                // 确保 weatherService.currentCityName 与 selectedLocation.name 一致
                if weatherService.currentCityName != selectedLocation.name {
                    print("警告：weatherService.currentCityName (\(weatherService.currentCityName ?? "nil")) 与 selectedLocation.name (\(selectedLocation.name)) 不一致，强制更新")
                    
                    // 清除当前天气数据并重新设置城市名称
                    weatherService.clearCurrentWeather()
                    weatherService.setCurrentCityName(selectedLocation.name)
                    
                    // 重新获取天气数据
                    await weatherService.updateWeather(
                        for: currentLocation,
                        cityName: selectedLocation.name
                    )
                    
                    print("手动设置当前城市名称：\(selectedLocation.name)")
                    
                    // 强制刷新 UI
                    await MainActor.run {
                        animationTrigger = UUID()
                    }
                }
            } else {
                print("地理编码未能获取城市名称")
            }
        } catch {
            print("地理编码失败: \(error.localizedDescription)")
        }
    }
    
    // 强制刷新 UI
    private func forceRefreshUI() {
        print("强制刷新 UI")
        animationTrigger = UUID()
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
