import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedLocation: PresetLocation
    let locations: [PresetLocation]
    var onLocationSelected: (PresetLocation) -> Void
    
    @State private var searchText = ""
    @State private var keyboardHeight: CGFloat = 0
    @StateObject private var citySearchService = CitySearchService.shared
    
    @State private var searchResults: [PresetLocation] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    
    private var filteredLocations: [PresetLocation] {
        if searchText.isEmpty {
            return []
        }
        return searchResults
    }
    
    private func performSearch() {
        // 取消之前的搜索任务
        searchTask?.cancel()
        
        // 如果搜索文本为空，直接清空结果
        if searchText.isEmpty {
            searchResults = []
            isSearching = false
            return
        }
        
        // 创建新的搜索任务
        searchTask = Task {
            isSearching = true
            
            // 添加短暂延迟，避免频繁搜索
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            // 检查任务是否已被取消
            if Task.isCancelled {
                return
            }
            
            // 执行搜索
            let results = await citySearchService.searchCities(query: searchText)
            
            // 确保在主线程更新 UI
            await MainActor.run {
                if !Task.isCancelled {
                    searchResults = results
                    isSearching = false
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                if isShowing {
                    // 背景遮罩
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                         to: nil, from: nil, for: nil)
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
                            
                            TextField("搜索全球城市", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.search)
                                .onChange(of: searchText) { _, newValue in
                                    performSearch()
                                }
                            
                            if isSearching {
                                ProgressView()
                                    .tint(.gray)
                            } else if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    searchResults.removeAll()
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                                 to: nil, from: nil, for: nil)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top, geometry.safeAreaInsets.top + 10)
                        
                        // 城市列表
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                if !searchText.isEmpty {
                                    if isSearching {
                                        ProgressView()
                                            .padding(.top, 20)
                                    } else if searchResults.isEmpty {
                                        Text("未找到匹配的城市")
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                    } else {
                                        ForEach(searchResults) { location in
                                            cityButton(for: location)
                                        }
                                    }
                                } else {
                                    // 最近搜索
                                    if !citySearchService.recentSearches.isEmpty {
                                        Text("最近搜索")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                            .padding(.horizontal, 20)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        ForEach(citySearchService.recentSearches) { location in
                                            cityButton(for: location)
                                        }
                                        
                                        Button(action: {
                                            citySearchService.clearRecentSearches()
                                        }) {
                                            Text("清除搜索记录")
                                                .font(.system(size: 15))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.top, 10)
                                    }
                                    
                                    // 热门城市
                                    Text("热门城市")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                        .padding(.horizontal, 20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    ForEach(citySearchService.getHotCities()) { city in
                                        cityButton(for: city)
                                    }
                                }
                            }
                            .padding(.bottom, keyboardHeight)
                        }
                        .padding(.top, 10)
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .frame(maxHeight: .infinity)
                    .background(
                        ZStack {
                            Color(red: 0.1, green: 0.1, blue: 0.2)
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                    .transition(.move(edge: .trailing))
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // 监听键盘显示/隐藏通知
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
        }
    }
    
    private func cityButton(for location: PresetLocation) -> some View {
        Button(action: {
            selectedLocation = location
            citySearchService.addToRecentSearches(location)
            onLocationSelected(location)
            searchText = ""
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                         to: nil, from: nil, for: nil)
            withAnimation {
                isShowing = false
            }
        }) {
            HStack {
                Text(location.name)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                if selectedLocation.id == location.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
        }
        .background(Color.white.opacity(0.01))
    }
} 