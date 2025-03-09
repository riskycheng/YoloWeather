import SwiftUI

struct LeftSideView: View {
    @Binding var isShowing: Bool
    @State private var dragOffset: CGFloat = 0
    @StateObject private var weatherService = WeatherService.shared
    @Binding var selectedLocation: PresetLocation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 半透明背景遮罩
                if isShowing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isShowing = false
                            }
                        }
                }
                
                // 左侧栏主容器
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        if let currentWeather = weatherService.currentWeather {
                            WeatherComparisonView(
                                weatherService: weatherService,
                                selectedLocation: selectedLocation
                            )
                            .padding(.top, 50)
                            .id(selectedLocation.id) // 添加 id 以在城市切换时强制刷新视图
                        } else {
                            ProgressView()
                                .tint(.white)
                                .padding()
                                .padding(.top, 50)
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.85, 340))
                    .background(
                        ZStack {
                            Color(red: 0.15, green: 0.2, blue: 0.3)
                            
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                            
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.05),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    )
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.1),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 1),
                        alignment: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 5, y: 0)
                    .offset(x: isShowing ? 0 : -min(geometry.size.width * 0.85, 340))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if value.translation.width < -50 {
                                        isShowing = false
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
                    
                    Spacer()
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShowing)
            .onChange(of: selectedLocation) { _, newLocation in
                // 当选择的城市发生变化时，确保加载该城市的天气数据
                Task {
                    await loadWeatherForSelectedLocation()
                }
            }
            .onChange(of: isShowing) { _, newValue in
                // 当左侧栏显示时，确保加载选中城市的天气数据
                if newValue {
                    Task {
                        await loadWeatherForSelectedLocation()
                    }
                }
            }
            .task {
                // 初始加载时，确保加载选中城市的天气数据
                if isShowing {
                    await loadWeatherForSelectedLocation()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onChange(of: selectedLocation) { _, newLocation in
            // 当选择的城市发生变化时，打印日志以便调试
            if let currentWeather = weatherService.currentWeather {
                print("\n=== 左侧栏天气数据更新 ===")
                print("城市：\(newLocation.name)")
                print("当前温度：\(Int(round(currentWeather.temperature)))°")
                print("天气状况：\(currentWeather.condition)")
                print("最高温度：\(Int(round(currentWeather.highTemperature)))°")
                print("最低温度：\(Int(round(currentWeather.lowTemperature)))°")
            }
        }
    }
    
    // 加载选中城市的天气数据
    private func loadWeatherForSelectedLocation() async {
        // 如果当前天气数据不是选中城市的，或者没有天气数据，则加载选中城市的天气数据
        if weatherService.currentCityName != selectedLocation.name || weatherService.currentWeather == nil {
            await weatherService.updateWeather(
                for: selectedLocation.location,
                cityName: selectedLocation.name
            )
        }
    }
}