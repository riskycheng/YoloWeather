import SwiftUI

struct SideMenuView: View {
    @Binding var isShowing: Bool
    @Binding var selectedLocation: PresetLocation
    let locations: [PresetLocation]
    var onLocationSelected: (PresetLocation) -> Void
    
    @State private var searchText = ""
    @State private var keyboardHeight: CGFloat = 0
    @StateObject private var citySearchService = CitySearchService.shared
    
    private var filteredLocations: [PresetLocation] {
        if searchText.isEmpty {
            return locations
        }
        let results = citySearchService.searchCities(query: searchText)
        return results
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
                            
                            TextField("搜索城市", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .submitLabel(.search)
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
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
                                    if filteredLocations.isEmpty {
                                        Text("未找到匹配的城市")
                                            .foregroundColor(.gray)
                                            .padding(.top, 20)
                                    } else {
                                        ForEach(filteredLocations) { location in
                                            cityButton(for: location)
                                        }
                                    }
                                } else {
                                    ForEach(locations) { location in
                                        cityButton(for: location)
                                    }
                                    
                                    Text("热门城市")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                        .padding(.horizontal, 20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    ForEach(citySearchService.getHotCities()) { city in
                                        if !locations.contains(where: { $0.id == city.id }) {
                                            cityButton(for: city)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, keyboardHeight) // 添加底部padding以适应键盘
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