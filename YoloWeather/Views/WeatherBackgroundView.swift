import SwiftUI

struct WeatherBackgroundView: View {
    @Environment(\.weatherTimeOfDay) var timeOfDay
    let weatherCondition: String
    @State private var centerScale: CGFloat = 1.0
    @State private var cloudOffset1: CGFloat = -200
    @State private var cloudOffset2: CGFloat = 200
    
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
                
                // 中央图标
                Group {
                    if timeOfDay == .night {
                        // 夜间显示月亮和云
                        ZStack {
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
                            
                            // 月亮
                            Image("full_moon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .scaleEffect(centerScale)
                        }
                        .offset(x: geometry.size.width * 0.1)
                    } else {
                        // 白天根据天气显示太阳或云
                        if weatherCondition.contains("晴") {
                            Image("sunny")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .scaleEffect(centerScale)
                        } else {
                            Image("cloudy")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .scaleEffect(centerScale)
                        }
                    }
                }
                .offset(y: -geometry.size.height * 0.25)
                .onAppear {
                    // 中央图标缩放动画
                    withAnimation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true)
                    ) {
                        centerScale = 1.1
                    }
                    
                    // 云朵移动动画
                    withAnimation(
                        .linear(duration: 8)
                        .repeatForever(autoreverses: false)
                    ) {
                        cloudOffset1 = geometry.size.width
                    }
                    
                    withAnimation(
                        .linear(duration: 12)
                        .repeatForever(autoreverses: false)
                    ) {
                        cloudOffset2 = -geometry.size.width
                    }
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
    
    private var colors: [Color] {
        if timeOfDay == .night {
            return [Color(hex: 0x1A237E), Color(hex: 0x0D47A1)] // 夜晚
        } else {
            return weatherCondition.contains("晴") ?
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

struct WeatherBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeatherBackgroundView(weatherCondition: "晴天")
                .previewDisplayName("Day")
            
            WeatherBackgroundView(weatherCondition: "晴天")
                .environment(\.weatherTimeOfDay, .night)
                .previewDisplayName("Night")
        }
    }
}
