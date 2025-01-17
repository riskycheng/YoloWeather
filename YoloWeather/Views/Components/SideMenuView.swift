import SwiftUI

// 天气信息视图组件
private struct WeatherInfoView: View {
    let weather: WeatherService.CurrentWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 温度行
            HStack {
                Spacer()
                Text("\(Int(round(weather.temperature)))°")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // 天气详情行
            HStack {
                Text(weather.weatherCondition.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("最高\(Int(round(weather.temperature + 3)))° 最低\(Int(round(weather.temperature - 3)))°")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// 城市卡片组件
struct SavedCityCard: View {
    let location: PresetLocation
    let action: () -> Void
    let onDelete: () -> Void
    @StateObject private var weatherService = WeatherService.shared
    @State private var timeOfDay: WeatherTimeOfDay = .day
    @State private var weather: WeatherService.CurrentWeather?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 第一行：城市名和当前温度
                HStack {
                    Text(location.name)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(round(weather?.temperature ?? 0)))°")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // 第二行：天气状况和温度范围
                HStack {
                    Text(weather?.weatherCondition.description ?? "获取中...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("最高\(Int(round((weather?.temperature ?? 0) + 3)))° 最低\(Int(round((weather?.temperature ?? 0) - 3)))°")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(WeatherThemeManager.shared.cardBackgroundColor(for: timeOfDay))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .task {
            // 只在卡片出现时获取一次天气数据
            await weatherService.updateWeather(for: location.location)
            weather = weatherService.currentWeather
        }
    }
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
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                if isShowing {
                    // 背景遮罩
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isShowing = false
                            }
                        }
                    
                    // 侧边栏内容
                    VStack(spacing: 0) {
                        // 搜索框
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("搜索城市", text: $searchText)
                                .textFieldStyle(.plain)
                                .submitLabel(.search)
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
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding()
                        
                        ScrollView {
                            VStack(spacing: 20) {
                                if searchText.isEmpty {
                                    // 收藏的城市
                                    if !citySearchService.recentSearches.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("收藏城市")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                                .padding(.horizontal)
                                            
                                            VStack(spacing: 8) {
                                                ForEach(citySearchService.recentSearches) { location in
                                                    SavedCityCard(
                                                        location: location,
                                                        action: {
                                                            handleLocationSelection(location)
                                                        },
                                                        onDelete: {
                                                            citySearchService.removeFromRecentSearches(location)
                                                        }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                } else {
                                    // 搜索结果
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
                                                    }
                                                )
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: .trailing))
                }
            }
            .onChange(of: isShowing) { newValue in
                if !newValue {
                    // 当菜单关闭时，清空搜索状态
                    searchText = ""
                    searchResults = []
                    showSearchResults = false
                    isSearching = false
                }
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
        withAnimation(.easeInOut) {
            isShowing = false
        }
        // 不再自动添加到收藏列表
        onLocationSelected(location)
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
