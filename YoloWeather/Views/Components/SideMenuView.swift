import SwiftUI

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
    @State private var searchOpacity: Double = 1.0
    
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
                                    performSearch()
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        searchText = ""
                                        searchResults = []
                                        showSearchResults = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            if isSearching {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.systemGray6))
                        )
                        .padding()
                        
                        // 内容区域
                        ZStack {
                            // 热门城市和最近搜索
                            VStack(alignment: .leading, spacing: 8) {
                                if !searchText.isEmpty && isSearching {
                                    // 搜索加载动画
                                    VStack(spacing: 16) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("正在搜索...")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .transition(.opacity)
                                } else if !searchText.isEmpty && showSearchResults {
                                    // 搜索结果
                                    ScrollView {
                                        VStack(spacing: 0) {
                                            if searchResults.isEmpty {
                                                VStack(spacing: 12) {
                                                    Image(systemName: "magnifyingglass")
                                                        .font(.title)
                                                        .foregroundColor(.gray)
                                                    Text("未找到匹配的城市")
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .padding(.top, 40)
                                            } else {
                                                ForEach(searchResults) { location in
                                                    LocationRow(location: location) {
                                                        handleLocationSelection(location)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .transition(.opacity)
                                } else {
                                    // 默认显示内容
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 16) {
                                            // 热门城市
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("热门城市")
                                                    .font(.headline)
                                                    .padding(.horizontal)
                                                
                                                ForEach(citySearchService.getHotCities()) { location in
                                                    LocationRow(location: location) {
                                                        handleLocationSelection(location)
                                                    }
                                                }
                                            }
                                            
                                            // 最近搜索
                                            if !citySearchService.recentSearches.isEmpty {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    HStack {
                                                        Text("最近搜索")
                                                            .font(.headline)
                                                        Spacer()
                                                        Button(action: {
                                                            withAnimation {
                                                                citySearchService.clearRecentSearches()
                                                            }
                                                        }) {
                                                            Text("清除")
                                                                .font(.subheadline)
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                    .padding(.horizontal)
                                                    
                                                    ForEach(citySearchService.recentSearches) { location in
                                                        LocationRow(location: location) {
                                                            handleLocationSelection(location)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.top)
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .opacity(searchOpacity)
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .background(Color(UIColor.systemBackground))
                    .transition(.move(edge: .trailing))
                }
            }
        }
    }
    
    private func performSearch() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSearching = true
            searchOpacity = 0.5
        }
        
        Task {
            let results = await citySearchService.searchCities(query: searchText)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                searchResults = results
                isSearching = false
                showSearchResults = true
                searchOpacity = 1.0
            }
        }
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