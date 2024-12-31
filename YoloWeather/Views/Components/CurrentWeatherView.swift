import SwiftUI

struct TemperatureRangeView: View {
    let lowTemp: Double
    let highTemp: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(Int(round(lowTemp)))°")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
            
            Text("—")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 8)
            
            Image(systemName: "arrow.up")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            Text("\(Int(round(highTemp)))°")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.black.opacity(0.3))
        }
        .overlay {
            Capsule()
                .stroke(LinearGradient(
                    colors: [.white.opacity(0.5), .white.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct LocationHeaderView: View {
    let location: String
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .imageScale(.small)
                .foregroundStyle(.white.opacity(0.9))
            
            if isLoading {
                Text("正在获取位置...")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.opacity)
            } else {
                Text(location)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .transition(.opacity)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 16)
        .background {
            Capsule()
                .fill(.black.opacity(0.3))
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .animation(.easeInOut, value: isLoading)
    }
}

struct CurrentWeatherView: View {
    let location: String
    let weather: WeatherInfo
    let isLoading: Bool
    let dailyForecast: [DayWeatherInfo]
    
    @State private var showContent = false
    @State private var loadingStartTime: Date? = nil
    @State private var shouldShowLoading = false
    
    private let minimumLoadingDuration: TimeInterval = 2.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Location
            LocationHeaderView(location: location, isLoading: isLoading)
                .transition(.move(edge: .top).combined(with: .opacity))
            
            Spacer()
            
            if shouldShowLoading {
                WeatherLoadingView()
                    .transition(.opacity)
            } else {
                // Large temperature display
                Text("\(Int(round(weather.temperature)))")
                    .font(.system(size: 180, weight: .ultraLight))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.7), radius: 3, x: 0, y: 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                    .opacity(showContent ? 1 : 0)
                
                // Weather condition
                Text(weather.condition)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            
            Spacer()
            
            if !shouldShowLoading, let todayForecast = dailyForecast.first {
                TemperatureRangeView(
                    lowTemp: todayForecast.lowTemperature,
                    highTemp: todayForecast.highTemperature
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
        }
        .frame(maxHeight: .infinity)
        .onChange(of: isLoading) { newValue in
            if newValue {
                // 开始加载
                loadingStartTime = Date()
                shouldShowLoading = true
                withAnimation(.easeOut(duration: 0.2)) {
                    showContent = false
                }
            } else {
                // 计算已经显示的时间
                let elapsedTime = Date().timeIntervalSince(loadingStartTime ?? Date())
                let remainingTime = max(0, minimumLoadingDuration - elapsedTime)
                
                // 延迟隐藏加载动画
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        shouldShowLoading = false
                    }
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showContent = true
                    }
                }
            }
        }
        .onAppear {
            if !isLoading {
                shouldShowLoading = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showContent = true
                }
            } else {
                shouldShowLoading = true
                loadingStartTime = Date()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        CurrentWeatherView(
            location: "Shanghai",
            weather: WeatherInfo(
                date: Date(),
                temperature: 25,
                condition: "Sunny",
                symbolName: "sun.max.fill"
            ),
            isLoading: false,
            dailyForecast: [
                DayWeatherInfo(
                    date: Date(),
                    condition: "Sunny",
                    symbolName: "sun.max.fill",
                    lowTemperature: 20,
                    highTemperature: 28
                )
            ]
        )
    }
}
