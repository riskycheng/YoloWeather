import SwiftUI

struct WeatherBackgroundView: View {
    @Environment(\.weatherTimeOfDay) var timeOfDay
    @ObservedObject var weatherService: WeatherService
    let weatherCondition: String
    @State private var centerScale: CGFloat = 1.0
    @State private var cloudOffset1: CGFloat = -200
    @State private var cloudOffset2: CGFloat = 200
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
                
                // 中央图标
                Group {
                    if timeOfDay == .night {
                        // 夜间显示月亮和云
                        ZStack {
                            // 月亮
                            Image("moon_stars")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .scaleEffect(centerScale)
                            
                            // 移动的云1
                            Image("cloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                                .opacity(0.6)
                                .offset(x: cloudOffset1)
                            
                            // 移动的云2
                            Image("cloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                                .opacity(0.4)
                                .offset(x: cloudOffset2, y: 50)
                        }
                        .offset(x: geometry.size.width * 0.1)
                    } else {
                        // 白天根据天气显示对应图标
                        let condition = currentWeatherCondition.lowercased()
                        switch condition {
                        case let c where c.contains("sunny") || c.contains("clear"):
                            Image("sunny")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .scaleEffect(centerScale)
                        case let c where c.contains("cloud") || c.contains("overcast"):
                            Image("cloud")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .scaleEffect(centerScale)
                        case let c where c.contains("rain"):
                            Image("rain")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .scaleEffect(centerScale)
                        case let c where c.contains("snow"):
                            Image("snow")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .scaleEffect(centerScale)
                        case let c where c.contains("fog") || c.contains("haze"):
                            Image("fog")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .scaleEffect(centerScale)
                        default:
                            // 如果不确定，根据是否包含 sunny 来决定
                            if condition.contains("sunny") {
                                Image("sunny")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .scaleEffect(centerScale)
                            } else {
                                Image("cloudy")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .scaleEffect(centerScale)
                            }
                        }
                    }
                }
                .offset(y: -geometry.size.height * 0.25)
                .onAppear {
                    startAnimations(geometry: geometry)
                }
                .onChange(of: currentWeatherCondition) { oldValue, newValue in
                    startAnimations(geometry: geometry)
                }
                
                // 地面装饰
                HStack {
                    // 左侧
                    VStack {
                        if timeOfDay == .night {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    
                    Spacer()
                    
                    // 右侧
                    VStack {
                        if timeOfDay == .night {
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing)
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func startAnimations(geometry: GeometryProxy) {
        // 重置所有动画状态
        centerScale = 1.0
        cloudOffset1 = -200
        cloudOffset2 = 200
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
            
            // 云朵移动动画（减慢速度）
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                cloudOffset1 = geometry.size.width
            }
            
            withAnimation(
                .linear(duration: 25)
                .repeatForever(autoreverses: false)
            ) {
                cloudOffset2 = -geometry.size.width
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
