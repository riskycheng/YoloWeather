import SwiftUI

struct LeftSideView: View {
    @Binding var isShowing: Bool
    @State private var dragOffset: CGFloat = 0
    @StateObject private var weatherService = WeatherService.shared
    
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
                            WeatherComparisonView(weatherService: weatherService)
                                .padding(.horizontal)
                        } else {
                            ProgressView()
                                .tint(.white)
                                .padding()
                        }
                        
                        Spacer()
                    }
                    .frame(width: min(geometry.size.width * 0.75, 300))
                    .background(Color(red: 0.25, green: 0.35, blue: 0.45))
                    .offset(x: isShowing ? 0 : -min(geometry.size.width * 0.75, 300))
                    
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
    }
} 