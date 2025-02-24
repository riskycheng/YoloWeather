import SwiftUI

struct RefreshableView<Content: View>: View {
    let content: Content
    let action: () async -> Void
    @Binding var isRefreshing: Bool
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    @StateObject private var weatherService = WeatherService.shared
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var hasTriggeredHaptic = false
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
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 18
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 下拉刷新指示器
                if dragOffset > 0 && !isRefreshing {
                    VStack(spacing: 8) {
                        Image(isDayTime ? "sunny" : "full_moon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(Double((dragOffset / threshold) * 180)))
                        
                        Text(dragOffset > threshold ? "释放刷新" : "下拉刷新")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .frame(width: geometry.size.width)
                    .frame(height: dragOffset)
                    .opacity(Double(min(dragOffset / 50, 1.0)))
                }
                
                content
                    .offset(y: dragOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        guard !isRefreshing else { return }
                        if value.translation.height > 0 {
                            state = value.translation.height
                            
                            // 当达到阈值时触发触觉反馈
                            if value.translation.height > threshold && !hasTriggeredHaptic {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred()
                                hasTriggeredHaptic = true
                            }
                        }
                    }
                    .onEnded { value in
                        guard !isRefreshing else { return }
                        hasTriggeredHaptic = false
                        if value.translation.height > threshold {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isRefreshing = true
                            }
                            Task {
                                await action()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = false
                                }
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
