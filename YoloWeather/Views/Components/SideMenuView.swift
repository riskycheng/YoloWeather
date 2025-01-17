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
    @StateObject private var weatherService = WeatherService.shared
    @State private var timeOfDay: WeatherTimeOfDay = .day
    @State private var currentWeather: WeatherService.CurrentWeather?
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                // 城市名称
                Text(location.name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                // 天气信息
                if let weather = weatherService.currentWeather {
                    WeatherInfoView(weather: weather)
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
                                                ForEach(Array(Set(citySearchService.recentSearches))) { location in
                                                    SavedCityCard(location: location) {
                                                        handleLocationSelection(location)
                                                    }
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
                                                SavedCityCard(location: location) {
                                                    handleLocationSelection(location)
                                                }
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
        citySearchService.addToRecentSearches(location)
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
