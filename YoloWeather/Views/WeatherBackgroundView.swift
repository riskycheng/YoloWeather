import SwiftUI

struct WeatherBackgroundView: View {
    @Environment(\.weatherTimeOfDay) var timeOfDay
    @ObservedObject var weatherService: WeatherService
    let weatherCondition: String
    @State private var centerScale: CGFloat = 1.0
    @State private var sparkleOpacities: [Double] = Array(repeating: 0.0, count: 20)
    @State private var sparkleScales: [CGFloat] = []
    @State private var sparklePositions: [(CGFloat, CGFloat)] = []
    
    private var currentWeatherCondition: String {
        weatherService.currentWeather?.condition ?? weatherCondition
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 夜间星星
                if timeOfDay == .night {
                    // 小圆点星星
                    ForEach(0..<20) { index in
                        Circle()
                            .fill(.white)
                            .frame(width: 2, height: 2)
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height * 0.6)
                            )
                            .opacity(sparkleOpacities[index])
                    }
                    
                    // 静态 Sparkles 图标
                    ForEach(Array(sparklePositions.enumerated()), id: \.offset) { index, position in
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32)
                            .scaleEffect(sparkleScales[index], anchor: UnitPoint.center)
                            .position(
                                x: geometry.size.width * position.0,
                                y: geometry.size.height * position.1
                            )
                    }
                }
            }
            .onAppear {
                startAnimations(geometry: geometry)
            }
        }
    }
    
    private func startAnimations(geometry: GeometryProxy) {
        // 重置所有动画状态
        centerScale = 1.0
        sparkleOpacities = Array(repeating: 0.0, count: 20)
        
        // 延迟一帧后开始新的动画，确保状态重置生效
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 随机生成 sparkles
            let count = Int.random(in: 2...4)
            sparkleScales = Array(repeating: 1.0, count: count)
            
            // 生成随机但均匀分布的位置，避开月亮区域
            var positions: [(CGFloat, CGFloat)] = []
            let sections = count + 1  // 将屏幕分成比sparkle数量多1的区域
            
            for i in 0..<count {
                let sectionWidth = 0.8 / CGFloat(sections)  // 总宽度使用80%屏幕
                let xStart = 0.1 + sectionWidth * CGFloat(i + 1)  // 从10%开始，留出边距
                let x = CGFloat.random(in: 
                    xStart...(xStart + sectionWidth * 0.8)  // 在每个区域内随机，但保持一定间距
                )
                
                // y坐标避开月亮区域（月亮大约在 0.25 高度处）
                let y: CGFloat
                if x > 0.3 && x < 0.7 {  // 中间区域
                    // 在上方或下方随机
                    y = CGFloat.random(in: Bool.random() ? 0.1...0.15 : 0.35...0.4)
                } else {
                    // 两侧区域可以使用更大范围
                    y = CGFloat.random(in: 0.1...0.4)
                }
                
                positions.append((x, y))
            }
            
            sparklePositions = positions
            
            // 中央图标缩放动画
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                centerScale = 1.1
            }
            
            // 星星闪烁动画
            for index in 0..<20 {
                let delay = Double.random(in: 0...3)
                let duration = Double.random(in: 1...2)
                
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    sparkleOpacities[index] = Double.random(in: 0.3...0.7)
                }
            }
            
            // Sparkles 缩放动画
            for index in 0..<sparkleScales.count {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2...4))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...2))
                ) {
                    sparkleScales[index] = CGFloat.random(in: 0.8...1.2)
                }
            }
        }
    }
    
    private var colors: [Color] {
        if timeOfDay == .night {
            return [Color(hex: 0x1A237E), Color(hex: 0x0D47A1)] // 夜晚
        } else {
            return currentWeatherCondition.contains("晴") ?
                [Color(hex: 0x64B5F6), Color(hex: 0x2196F3)] :  // 晴天
                [Color(hex: 0x90CAF9), Color(hex: 0x42A5F5)]    // 多云
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

#if DEBUG
struct WeatherBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherBackgroundView(
            weatherService: WeatherService.shared,
            weatherCondition: "晴"
        )
        .environment(\.weatherTimeOfDay, .day)
    }
}
#endif
