import SwiftUI
import CoreLocation
import WeatherKit

// 添加 View 扩展
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

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
        
        do {
            // 使用 WeatherService 获取天气数据，一定要传入城市名称
            await WeatherService.shared.updateWeather(for: location.location, cityName: location.name)
            
            // 从缓存中获取更新后的天气数据
            if let updatedWeather = WeatherService.shared.getCachedWeather(for: location.name) {
                withAnimation {
                    self.weather = updatedWeather
                }
            }
        } catch {
            // 错误处理
            print("加载天气数据失败: \(error.localizedDescription)")
            self.weather = nil
        }
    }
}

// 温度显示组件
private struct TemperatureView: View {
    let weather: WeatherService.CurrentWeather?
    let isLoading: Bool
    let isEditMode: Bool
    
    var body: some View {
        if isEditMode {
            // 编辑模式下显示缓存的温度
            if let weather = weather {
                Text("\(Int(round(weather.temperature)))°")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Text("--°")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        } else if isLoading {
            Text("获取中...")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        } else if let weather = weather {
            Text("\(Int(round(weather.temperature)))°")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        } else {
            Text("--°")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// 天气详情组件
private struct WeatherDetailsView: View {
    let weather: WeatherService.CurrentWeather?
    let isLoading: Bool
    let isEditMode: Bool
    
    var body: some View {
        if isEditMode {
            // 编辑模式下显示缓存的天气信息
            if let weather = weather {
                weatherInfoContent(weather)
            } else {
                Text("暂无数据")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        } else if isLoading {
            Text("获取中...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        } else if let weather = weather {
            weatherInfoContent(weather)
        } else {
            Text("暂无数据")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func weatherInfoContent(_ weather: WeatherService.CurrentWeather) -> some View {
        HStack {
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
            if !isEditMode {
                await loadWeather()
            }
        }
        .onAppear {
            if !isEditMode {
                Task {
                    await loadWeather()
                }
            }
        }
        .onChange(of: location) { oldValue, newValue in
            if !isEditMode {
                Task {
                    await loadWeather()
                }
            }
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 4) {
            cityHeader
            WeatherDetailsView(
                weather: WeatherService.shared.getCachedWeather(for: location.name),
                isLoading: isLoading,
                isEditMode: isEditMode
            )
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
            
            TemperatureView(
                weather: WeatherService.shared.getCachedWeather(for: location.name),
                isLoading: isLoading,
                isEditMode: isEditMode
            )
        }
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
                Button(action: onDelete) {
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
                gestureState = currentState
            }
            .onEnded { _ in
                withAnimation {
                    isEditMode = true
                }
            }
    }
    
    private func loadWeather() async {
        guard !isEditMode else { return }
        
        isLoading = true
        
        // 如果是预设城市，使用预设的坐标
        let cityLocation: CLLocation
        if let presetLocation = CitySearchService.shared.allCities.first(where: { $0.name == location.name }) {
            cityLocation = presetLocation.location
        } else {
            cityLocation = location.location
        }
        
        // 先尝试从缓存获取天气数据
        if let cachedWeather = WeatherService.shared.getCachedWeather(for: location.name) {
            self.weather = cachedWeather
            isLoading = false
            return
        }
        
        // 如果缓存中没有，则更新天气数据
        await WeatherService.shared.updateWeather(for: cityLocation, cityName: location.name)
        
        // 更新完成后，从缓存中获取天气数据
        if let updatedWeather = WeatherService.shared.getCachedWeather(for: location.name) {
            self.weather = updatedWeather
        }
        
        isLoading = false
    }
}

// 添加拖拽状态
private struct DragState {
    var dragging: PresetLocation?
    var translation: CGSize = .zero
    var startLocation: CGPoint = .zero
    var currentLocation: CGPoint = .zero
}

// 搜索栏组件
private struct SearchBarView: View {
    @Binding var searchText: String
    var onSubmit: () async -> Void
    
    var body: some View {
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
                        await onSubmit()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
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

// 顶部栏组件
private struct TopBarView: View {
    @Binding var isEditMode: Bool
    @Binding var searchText: String
    var onSubmit: () async -> Void
    
    var body: some View {
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
                SearchBarView(searchText: $searchText, onSubmit: onSubmit)
            }
        }
        .padding()
    }
}

// 主内容区域组件
private struct MainContentView: View {
    @Binding var isEditMode: Bool
    @StateObject var citySearchService: CitySearchService
    @Binding var selectedLocation: PresetLocation
    let searchText: String
    let searchResults: [PresetLocation]
    let isSearching: Bool
    let onLocationSelected: (PresetLocation) -> Void
    let cardHeight: CGFloat
    let cardSpacing: CGFloat
    @Binding var dragState: DragState
    @Binding var draggingItem: PresetLocation?
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 16) {
                if searchText.isEmpty {
                    // 收藏的城市
                    if !citySearchService.recentSearches.isEmpty {
                        savedCitiesSection
                    }
                } else {
                    searchResultsList
                }
            }
            .padding(.vertical)
            // Add bottom padding to ensure last item is not hidden behind home bar
            .padding(.bottom, 34)
        }
        .scrollDisabled(isEditMode)
        .frame(maxHeight: .infinity)
    }
    
    private var savedCitiesSection: some View {
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
                    .gesture(makeLongPressGesture(for: location))
                    .simultaneousGesture(makeDragGesture(for: location))
                }
                
                Color.clear.frame(height: 12)
            }
            .padding(.horizontal)
        }
    }
    
    private func handleLocationSelection(_ location: PresetLocation) {
        onLocationSelected(location)
    }
    
    private func offsetFor(_ location: PresetLocation) -> CGFloat {
        let itemHeight = cardHeight + cardSpacing
        
        if draggingItem == location {
            return dragState.translation.height
        }
        
        guard let currentIndex = citySearchService.recentSearches.firstIndex(of: location),
              let draggingIndex = draggingItem.flatMap({ citySearchService.recentSearches.firstIndex(of: $0) }) else {
            return 0
        }
        
        let targetPosition = itemHeight * CGFloat(currentIndex)
        let draggingPosition = itemHeight * CGFloat(draggingIndex) + dragState.translation.height
        
        if currentIndex > draggingIndex && draggingPosition > targetPosition {
            return -itemHeight
        } else if currentIndex < draggingIndex && draggingPosition < targetPosition {
            return itemHeight
        }
        
        return 0
    }
    
    private func makeLongPressGesture(for location: PresetLocation) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onChanged { _ in
                if draggingItem == nil {
                    withAnimation {
                        isEditMode = true
                    }
                }
            }
    }
    
    private func makeDragGesture(for location: PresetLocation) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { gesture in
                handleDragChange(gesture: gesture, location: location)
            }
            .onEnded { _ in
                handleDragEnd()
            }
    }
    
    private func handleDragChange(gesture: DragGesture.Value, location: PresetLocation) {
        guard isEditMode && (draggingItem == nil || draggingItem == location) else { return }
        
        if draggingItem == nil {
            initiateDrag(for: location, at: gesture.location)
            return
        }
        
        if draggingItem == location {
            updateDragPosition(gesture: gesture, location: location)
        }
    }
    
    private func initiateDrag(for location: PresetLocation, at point: CGPoint) {
        draggingItem = location
        dragState.startLocation = point
        dragState.currentLocation = point
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func updateDragPosition(gesture: DragGesture.Value, location: PresetLocation) {
        dragState.translation = CGSize(
            width: 0,
            height: gesture.location.y - dragState.startLocation.y
        )
        dragState.currentLocation = gesture.location
        
        updateItemPosition(for: location, with: gesture)
    }
    
    private func updateItemPosition(for location: PresetLocation, with gesture: DragGesture.Value) {
        guard let currentIndex = citySearchService.recentSearches.firstIndex(of: location) else { return }
        
        let itemHeight = cardHeight + cardSpacing
        let headerHeight: CGFloat = 12
        
        let startY = headerHeight + (itemHeight * CGFloat(currentIndex))
        let currentY = startY + dragState.translation.height
        
        let proposedIndex = Int(round((currentY - headerHeight) / itemHeight))
        let targetIndex = max(0, min(citySearchService.recentSearches.count - 1, proposedIndex))
        
        if targetIndex != currentIndex && abs(currentY - startY) > itemHeight / 2 {
            moveItem(from: currentIndex, to: targetIndex, gesture: gesture)
        }
    }
    
    private func moveItem(from currentIndex: Int, to targetIndex: Int, gesture: DragGesture.Value) {
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7)) {
            let fromOffset = IndexSet(integer: currentIndex)
            let toOffset = targetIndex > currentIndex ? targetIndex + 1 : targetIndex
            citySearchService.recentSearches.move(
                fromOffsets: fromOffset,
                toOffset: toOffset
            )
        }
        dragState.startLocation = gesture.location
        dragState.translation = .zero
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleDragEnd() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dragState = DragState()
            draggingItem = nil
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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

// 修改 SideMenuView 的实现
struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedLocation: PresetLocation
    let onLocationSelected: (PresetLocation) -> Void
    @StateObject private var citySearchService = CitySearchService.shared
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var isEditMode = false
    @State private var dragOffset: CGFloat = 0
    @State private var dragState = DragState()
    @State private var draggingItem: PresetLocation?
    @State private var searchResults: [PresetLocation] = []
    @State private var showSearchResults = false
    
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
                        TopBarView(
                            isEditMode: $isEditMode,
                            searchText: $searchText,
                            onSubmit: performSearch
                        )
                        .padding(.top, 50)  // 添加顶部间距
                        
                        MainContentView(
                            isEditMode: $isEditMode,
                            citySearchService: citySearchService,
                            selectedLocation: $selectedLocation,
                            searchText: searchText,
                            searchResults: searchResults,
                            isSearching: isSearching,
                            onLocationSelected: handleLocationSelection,
                            cardHeight: 80,
                            cardSpacing: 8,
                            dragState: $dragState,
                            draggingItem: $draggingItem
                        )
                        
                        WeatherBubbleSettingsView()
                            .padding(.bottom)
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .background(Color(red: 0.25, green: 0.35, blue: 0.45))
                    .offset(x: isShowing ? dragOffset : min(geometry.size.width * 0.75, 300))
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 只处理从左向右的滑动
                        if value.translation.width > 0 {
                            withAnimation(.interactiveSpring()) {
                                dragOffset = value.translation.width
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            // 如果滑动距离超过阈值，关闭侧边栏
                            if value.translation.width > geometry.size.width * 0.3 {
                                isShowing = false
                            }
                            dragOffset = 0
                        }
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isShowing)
            .onChange(of: isShowing) { newValue in
                if !newValue {
                    resetState()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .task {
            // 加载所有城市的天气数据
            await loadAllCitiesWeather()
        }
    }
    
    private func resetState() {
        searchText = ""
        searchResults = []
        showSearchResults = false
        isSearching = false
        isEditMode = false
    }
    
    private func performSearch() async {
        isSearching = true
        searchResults = await citySearchService.searchCities(query: searchText)
        isSearching = false
        showSearchResults = true
    }
    
    private func handleLocationSelection(_ location: PresetLocation) {
        if isEditMode {
            return
        }
        
        let cityLocation = CitySearchService.shared.allCities.first(where: { $0.name == location.name }) ?? location
        
        selectedLocation = cityLocation
        onLocationSelected(cityLocation)
        
        withAnimation {
            isShowing = false
        }
    }
    
    private func loadAllCitiesWeather() async {
        let cities = citySearchService.recentSearches.map { $0.name }
        await WeatherService.shared.batchUpdateWeather(for: cities)
    }
}
