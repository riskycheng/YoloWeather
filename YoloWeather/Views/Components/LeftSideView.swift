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
                            .padding(.top, 50) // 添加顶部间距以避免与 SafeArea 重叠
                        } else {
                            ProgressView()
                                .tint(.white)
                                .padding()
                                .padding(.top, 50) // 同样为加载状态添加顶部间距
                        }
                    }
                    .frame(width: min(geometry.size.width * 0.85, 340))
                    .background(
                        ZStack {
                            // 主背景色
                            Color(red: 0.15, green: 0.2, blue: 0.3)
                            
                            // 顶部渐变效果
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                            
                            // 侧边光效
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