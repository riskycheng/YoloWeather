import SwiftUI
import CoreLocation
import WeatherKit

// 天气信息视图组件
private struct WeatherInfoView: View {
    let location: PresetLocation
    @State private var weather: WeatherService.CurrentWeather?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 温度行
            HStack {
                Spacer()
                if isLoading {
                    Text("获取中...")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                } else if let weather = weather {
                    Text("\(Int(round(weather.temperature)))°")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            // 天气详情行
            HStack {
                if let weather = weather {
                    Text(weather.condition)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("最高\(Int(round(weather.highTemperature)))° 最低\(Int(round(weather.lowTemperature)))°")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .task {
            await loadWeather()
        }
    }
    
    private func loadWeather() async {
        isLoading = true
        defer { isLoading = false }
        
        print("SideMenuView - 开始加载城市天气: \(location.name)")
        print("SideMenuView - 城市坐标: 纬度 \(location.location.coordinate.latitude), 经度 \(location.location.coordinate.longitude)")
        
        do {
            // 使用 WeatherService 获取天气数据
            await WeatherService.shared.updateWeather(for: location.location)
            
            // 从 WeatherService 获取更新后的天气数据
            if let currentWeather = WeatherService.shared.currentWeather {
                self.weather = currentWeather
                print("SideMenuView - 成功更新城市天气: \(location.name)")
            }
        } catch {
            print("SideMenuView - 获取天气数据失败: \(error.localizedDescription)")
        }
    }
}

// 城市卡片组件
struct SavedCityCard: View {
    let location: PresetLocation
    let action: () -> Void
    let onDelete: () -> Void
    @State private var weather: WeatherService.CurrentWeather?
    @State private var isLoading = true
    @Binding var isEditMode: Bool
    @GestureState private var isDetectingLongPress = false
    
    var body: some View {
        Button(action: {
            if !isEditMode {
                action()
            }
        }) {
            cardContent
        }
        .simultaneousGesture(longPressGesture)
        .scaleEffect(isDetectingLongPress ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDetectingLongPress)
        .overlay(deleteButton, alignment: .topLeading)
        .modifier(ShakeEffect(isEditMode: isEditMode))
        .task {
            if weather == nil {
                await loadWeather()
            }
        }
        .onAppear {
            // 每次卡片出现时都刷新天气数据
            Task {
                await loadWeather()
            }
        }
        .onChange(of: location) { oldValue, newValue in
            // 当位置改变时刷新天气数据
            Task {
                await loadWeather()
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 4) {
            cityHeader
            weatherInfo
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .contentShape(Rectangle())
    }
    
    private var cityHeader: some View {
        HStack {
            Text(location.name)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            if isLoading {
                Text("获取中...")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Text("\(Int(round(weather?.temperature ?? 0)))°")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var weatherInfo: some View {
        HStack {
            if isLoading {
                Text("获取中...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text(weather?.condition ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if let weather = weather {
                    Text("最高\(Int(round(weather.highTemperature)))° 最低\(Int(round(weather.lowTemperature)))°")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    private func loadWeather() async {
        isLoading = true
        print("SavedCityCard - 开始加载城市天气: \(location.name)")
        
        // 如果是预设城市，使用预设的坐标
        let cityLocation: CLLocation
        if let presetLocation = CitySearchService.shared.allCities.first(where: { $0.name == location.name }) {
            cityLocation = presetLocation.location
            print("SavedCityCard - 使用预设城市坐标")
        } else {
            cityLocation = location.location
            print("SavedCityCard - 使用传入的坐标")
        }
        
        print("SavedCityCard - 城市坐标: 纬度 \(cityLocation.coordinate.latitude), 经度 \(cityLocation.coordinate.longitude)")
        
        do {
            // 使用 WeatherService 获取天气数据
            await WeatherService.shared.updateWeather(for: cityLocation)
            
            // 从 WeatherService 获取更新后的天气数据
            if let currentWeather = WeatherService.shared.currentWeather {
                self.weather = currentWeather
                print("SavedCityCard - 成功更新城市天气: \(location.name)")
            }
        } catch {
            print("SavedCityCard - 获取天气数据失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }
    
    private var deleteButton: some View {
        Group {
            if isEditMode {
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                }
                .offset(x: -8, y: -8)
            }
        }
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .updating($isDetectingLongPress) { currentState, gestureState, _ in
                print("Long press updating for: \(location.name)")
                gestureState = currentState
            }
            .onEnded { _ in
                print("Long press ended for: \(location.name)")
                withAnimation {
                    isEditMode = true
                }
            }
    }
}

// 添加拖拽状态
private struct DragState {
    var dragging: PresetLocation?
    var translation: CGSize = .zero
    var startLocation: CGPoint = .zero
    var currentLocation: CGPoint = .zero
}

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedLocation: PresetLocation
    let locations: [PresetLocation]
    let onLocationSelected: (PresetLocation) -> Void
    
    @StateObject private var citySearchService = CitySearchService.shared
    @State private var searchText = ""
    @State private var searchResults: [PresetLocation] = []
    @State private var isSearching = false
    @State private var showSearchResults = false
    @State private var isEditMode = false
    @State private var dragState = DragState()
    @State private var draggingItem: PresetLocation?
    private let cardHeight: CGFloat = 98
    private let cardSpacing: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // 半透明背景
                if isShowing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation {
                                isShowing = false
                            }
                        }
                }
                
                // 侧边栏主容器
                HStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // 顶部栏
                        HStack {
                            if isEditMode {
                                Button("完成") {
                                    withAnimation {
                                        isEditMode = false
                                    }
                                }
                                .foregroundColor(.white)
                                
                                Spacer()
                            } else {
                                // 搜索框
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(Color.white.opacity(0.4))
                                    
                                    TextField("搜索城市", text: $searchText)
                                        .textFieldStyle(.plain)
                                        .submitLabel(.search)
                                        .foregroundColor(.white)
                                        .accentColor(.white)
                                        .placeholder(when: searchText.isEmpty) {
                                            Text("搜索城市")
                                                .foregroundColor(Color.white.opacity(0.4))
                                        }
                                        .onSubmit {
                                            Task {
                                                await performSearch()
                                            }
                                        }
                                    
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            searchText = ""
                                            searchResults = []
                                            showSearchResults = false
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Color.white.opacity(0.4))
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        
                        // 主内容区域
                        VStack(spacing: 0) {
                            // 可滚动的城市列表区域
                            ScrollView {
                                VStack(spacing: 20) {
                                    if searchText.isEmpty {
                                        // 收藏的城市
                                        if !citySearchService.recentSearches.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text("收藏城市")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(Color.white.opacity(0.6))
                                                    Spacer()
                                                }
                                                .padding(.horizontal)
                                                .onLongPressGesture {
                                                    withAnimation {
                                                        isEditMode = true
                                                    }
                                                }
                                                
                                                if isEditMode {
                                                    editableLocationsList
                                                } else {
                                                    normalLocationsList
                                                }
                                            }
                                        }
                                    } else {
                                        searchResultsList
                                    }
                                }
                                .padding(.vertical)
                            }
                            .frame(maxHeight: .infinity)
                            
                            // 固定在底部的显示指标设置
                            WeatherBubbleSettingsView()
                                .padding(.bottom)
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .background(Color(red: 0.25, green: 0.35, blue: 0.45))
                }
                .offset(x: isShowing ? 0 : min(geometry.size.width * 0.75, 300))
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isShowing)
            }
            .onChange(of: isShowing) { newValue in
                if !newValue {
                    searchText = ""
                    searchResults = []
                    showSearchResults = false
                    isSearching = false
                    isEditMode = false
                }
            }
        }
    }
    
    private var normalLocationsList: some View {
        VStack(spacing: 8) {
            ForEach(citySearchService.recentSearches) { location in
                SavedCityCard(
                    location: location,
                    action: {
                        if !isEditMode {
                            handleLocationSelection(location)
                        }
                    },
                    onDelete: {
                        citySearchService.removeFromRecentSearches(location)
                    },
                    isEditMode: $isEditMode
                )
            }
        }
        .padding(.horizontal)
    }
    
    private var editableLocationsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: cardSpacing) {
                Color.clear.frame(height: 12)
                
                ForEach(citySearchService.recentSearches) { location in
                    SavedCityCard(
                        location: location,
                        action: {
                            // 编辑模式下禁用点击动作
                            if !isEditMode {
                                handleLocationSelection(location)
                            }
                        },
                        onDelete: {
                            citySearchService.removeFromRecentSearches(location)
                        },
                        isEditMode: $isEditMode
                    )
                    .offset(y: offsetFor(location))
                    .zIndex(draggingItem == location ? 1 : 0)
                    .scaleEffect(draggingItem == location ? 1.05 : 1.0)
                    .shadow(color: .black.opacity(draggingItem == location ? 0.2 : 0), radius: 10, x: 0, y: 5)
                    .animation(
                        .interactiveSpring(response: 0.35, dampingFraction: 0.86),
                        value: offsetFor(location)
                    )
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onChanged { _ in
                                if draggingItem == nil {
                                    withAnimation {
                                        isEditMode = true
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .global)  // 增加最小拖动距离，避免误触
                            .onChanged { gesture in
                                guard isEditMode && (draggingItem == nil || draggingItem == location) else { return }
                                
                                if draggingItem == nil {
                                    draggingItem = location
                                    dragState.startLocation = gesture.location
                                    dragState.currentLocation = gesture.location
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                                
                                if draggingItem == location {
                                    // 更新拖拽位置
                                    dragState.translation = CGSize(
                                        width: 0,
                                        height: gesture.location.y - dragState.startLocation.y
                                    )
                                    dragState.currentLocation = gesture.location
                                    
                                    // 计算目标位置
                                    if let currentIndex = citySearchService.recentSearches.firstIndex(of: location) {
                                        let itemHeight = cardHeight + cardSpacing
                                        let headerHeight: CGFloat = 12
                                        
                                        // 计算当前拖拽位置相对于起始位置的偏移
                                        let startY = headerHeight + (itemHeight * CGFloat(currentIndex))
                                        let currentY = startY + dragState.translation.height
                                        
                                        // 计算目标索引
                                        let proposedIndex = Int(round((currentY - headerHeight) / itemHeight))
                                        let targetIndex = max(0, min(citySearchService.recentSearches.count - 1, proposedIndex))
                                        
                                        // 只有当移动足够距离时才触发位置交换
                                        if targetIndex != currentIndex && abs(currentY - startY) > itemHeight / 2 {
                                            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7)) {
                                                let fromOffset = IndexSet(integer: currentIndex)
                                                let toOffset = targetIndex > currentIndex ? targetIndex + 1 : targetIndex
                                                citySearchService.recentSearches.move(
                                                    fromOffsets: fromOffset,
                                                    toOffset: toOffset
                                                )
                                            }
                                            // 更新起始位置
                                            dragState.startLocation = gesture.location
                                            dragState.translation = .zero
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                        }
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragState = DragState()
                                    draggingItem = nil
                                }
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                    )
                }
                
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal)
        }
        .scrollDisabled(isEditMode)
    }
    
    private func offsetFor(_ location: PresetLocation) -> CGFloat {
        let itemHeight = cardHeight + cardSpacing
        
        // 如果是被拖拽的卡片，直接跟随手指移动
        if draggingItem == location {
            return dragState.translation.height
        }
        
        guard let currentIndex = citySearchService.recentSearches.firstIndex(of: location),
              let draggingIndex = draggingItem.flatMap({ citySearchService.recentSearches.firstIndex(of: $0) }) else {
            return 0
        }
        
        // 计算补齐位置
        let targetPosition = itemHeight * CGFloat(currentIndex)
        let draggingPosition = itemHeight * CGFloat(draggingIndex) + dragState.translation.height
        
        if currentIndex > draggingIndex {
            // 如果当前卡片在拖拽卡片下方
            if draggingPosition > targetPosition {
                // 如果拖拽的卡片移动到了当前卡片之后，当前卡片向上移动
                return -itemHeight
            }
        } else if currentIndex < draggingIndex {
            // 如果当前卡片在拖拽卡片上方
            if draggingPosition < targetPosition {
                // 如果拖拽的卡片移动到了当前卡片之前，当前卡片向下移动
                return itemHeight
            }
        }
        
        return 0
    }
    
    private var searchResultsList: some View {
        Group {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if searchResults.isEmpty {
                Text("未找到匹配的城市")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(searchResults) { location in
                        SavedCityCard(
                            location: location,
                            action: {
                                handleLocationSelection(location)
                            },
                            onDelete: {
                                citySearchService.removeFromRecentSearches(location)
                            },
                            isEditMode: $isEditMode
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func performSearch() async {
        isSearching = true
        searchResults = await citySearchService.searchCities(query: searchText)
        isSearching = false
        showSearchResults = true
    }
    
    private func handleLocationSelection(_ location: PresetLocation) {
        print("SideMenuView - 选中城市: \(location.name)")
        
        // 如果是预设城市，使用预设的坐标
        let cityLocation: PresetLocation
        if let presetLocation = CitySearchService.shared.allCities.first(where: { $0.name == location.name }) {
            print("SideMenuView - 使用预设城市坐标")
            cityLocation = presetLocation
        } else {
            print("SideMenuView - 使用传入的坐标")
            cityLocation = location
        }
        
        print("SideMenuView - 城市坐标: 纬度 \(cityLocation.location.coordinate.latitude), 经度 \(cityLocation.location.coordinate.longitude)")
        
        // 更新选中的城市
        selectedLocation = cityLocation
        
        // 调用回调函数更新主视图
        print("SideMenuView - 正在调用回调函数更新主视图的天气数据...")
        onLocationSelected(cityLocation)
        
        // 最后关闭侧边栏
        withAnimation {
            isShowing = false
        }
    }
}

// 抖动效果修饰符
struct ShakeEffect: ViewModifier {
    let isEditMode: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isEditMode ? 0.98 : 1.0)
            .animation(
                isEditMode ? 
                    Animation.easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true) : 
                    .default,
                value: isEditMode
            )
    }
}

struct LocationRow: View {
    let location: PresetLocation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(location.name)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                Color(UIColor.systemBackground)
                    .contentShape(Rectangle())
            )
        }
    }
}

// 添加拖拽重定位代理
private struct DragRelocateDelegate: DropDelegate {
    let item: PresetLocation
    @Binding var listData: [PresetLocation]
    let draggedItem: PresetLocation
    
    func dropEntered(info: DropInfo) {
        guard let fromIndex = listData.firstIndex(of: draggedItem),
              let toIndex = listData.firstIndex(of: item),
              fromIndex != toIndex else { return }
        
        withAnimation(.default) {
            let fromOffset = IndexSet(integer: fromIndex)
            let toOffset = toIndex > fromIndex ? toIndex + 1 : toIndex
            listData.move(fromOffsets: fromOffset, toOffset: toOffset)
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        return true
    }
}

// 添加拖拽位置偏好键
private struct DragOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
