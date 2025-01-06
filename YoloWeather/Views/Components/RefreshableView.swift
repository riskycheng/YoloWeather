import SwiftUI

struct RefreshableView<Content: View>: View {
    let content: Content
    let action: () async -> Void
    @Binding var isRefreshing: Bool
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    @StateObject private var weatherService = WeatherService.shared
    
    @GestureState private var dragOffset: CGFloat = 0
    private let threshold: CGFloat = 100
    
    init(isRefreshing: Binding<Bool>, action: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.action = action
        self._isRefreshing = isRefreshing
    }
    
    private var isDayTime: Bool {
        if let weather = weatherService.currentWeather {
            return WeatherThemeManager.shared.determineTimeOfDay(for: Date(), in: weather.timezone) == .day
        }
        // Default to using local time if no weather data is available
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Add a clear background to capture gestures across the entire screen
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                content
                    .offset(y: dragOffset > 0 ? dragOffset : 0)
                
                if dragOffset > 0 || isRefreshing {
                    VStack {
                        if isRefreshing {
                            // 使用不同的图标基于时间
                            Image(isDayTime ? "sunny" : "full_moon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(
                                    Animation.linear(duration: 1)
                                        .repeatForever(autoreverses: false),
                                    value: isRefreshing
                                )
                        } else {
                            Image(isDayTime ? "sunny" : "full_moon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .rotationEffect(.degrees(min((dragOffset / threshold as CGFloat) * CGFloat(180), 180)))
                        }
                        
                        Text(dragOffset > threshold ? "释放刷新" : "下拉刷新")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .frame(width: geometry.size.width)
                    .frame(height: max(dragOffset, 0))
                    .opacity(min(dragOffset / 50, 1.0))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        guard !isRefreshing else { return }
                        if value.translation.height > 0 {
                            state = value.translation.height
                        }
                    }
                    .onEnded { value in
                        guard !isRefreshing else { return }
                        if value.translation.height > threshold {
                            isRefreshing = true
                            Task {
                                await action()
                                isRefreshing = false
                            }
                        }
                    }
            )
        }
    }
}

#Preview {
    RefreshableView(isRefreshing: .constant(false)) {
        // Refresh action
    } content: {
        Color.blue
    }
    .environment(\.weatherTimeOfDay, .day)
}
