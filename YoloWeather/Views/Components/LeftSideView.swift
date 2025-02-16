import SwiftUI

struct LeftSideView: View {
    @Binding var isShowing: Bool
    @State private var dragOffset: CGFloat = 0
    @StateObject private var weatherService = WeatherService.shared
    @Binding var selectedLocation: PresetLocation
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
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
                
                // 左侧栏主容器
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Text("天气趋势")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.top, 60)
                            .padding(.bottom, 20)
                        
                        if let currentWeather = weatherService.currentWeather {
                            WeatherComparisonView(
                                weatherService: weatherService,
                                selectedLocation: selectedLocation
                            )
                            .padding(.horizontal, 8)  // 减小水平内边距以增加卡片宽度
                        } else {
                            ProgressView()
                                .tint(.white)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    .frame(width: min(geometry.size.width * 0.85, 340))  // 增加侧边栏宽度
                    .background(Color(red: 0.25, green: 0.35, blue: 0.45))
                    .offset(x: isShowing ? 0 : -min(geometry.size.width * 0.85, 340))
                    
                    Spacer()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // 只处理从左向右的滑动
                        if !isShowing {
                            if value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        } else {
                            // 已经显示时，处理向左滑动关闭
                            if value.translation.width < 0 {
                                dragOffset = value.translation.width
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut) {
                            if !isShowing {
                                // 打开状态：如果右滑距离超过阈值，显示侧边栏
                                if value.translation.width > geometry.size.width * 0.15 {
                                    isShowing = true
                                }
                            } else {
                                // 关闭状态：如果左滑距离超过阈值，关闭侧边栏
                                if -value.translation.width > geometry.size.width * 0.15 {
                                    isShowing = false
                                }
                            }
                            dragOffset = 0
                        }
                    }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isShowing)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            if let currentWeather = weatherService.currentWeather {
                print("\n=== 当前天气趋势 ===")
                print("实时天气:")
                print("- 温度: \(Int(round(currentWeather.temperature)))°")
                print("- 天气: \(currentWeather.condition)")
                print("- 体感温度: \(Int(round(currentWeather.feelsLike)))°")
                
                print("\n未来24小时天气:")
                for (index, forecast) in weatherService.hourlyForecast.prefix(24).enumerated() {
                    print("[\(index + 1)小时后] 温度: \(Int(round(forecast.temperature)))° 天气: \(forecast.conditionText)")
                }
                
                print("\n未来7天天气:")
                for (index, forecast) in weatherService.dailyForecast.prefix(7).enumerated() {
                    print("第\(index + 1)天:")
                    print("- 最高温: \(Int(round(forecast.highTemperature)))°")
                    print("- 最低温: \(Int(round(forecast.lowTemperature)))°")
                    print("- 天气: \(forecast.condition)")
                }
            }
        }
    }
}