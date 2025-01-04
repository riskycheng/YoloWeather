import SwiftUI

struct WeatherBackgroundView: View {
    let timeOfDay: WeatherTimeOfDay
    @State private var cloudOffsets: [CGFloat] = [-200, -400, -600]
    @State private var cloudScales: [CGFloat] = [1.0, 1.0, 1.0]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // 飘动的云或星星
                ForEach(0..<3) { index in
                    Image(timeOfDay == .day ? "cloudy" : "moon_stars")
                        .resizable()
                        .scaledToFit()
                        .frame(width: [100, 80, 120][index])
                        .opacity(0.8)
                        .scaleEffect(cloudScales[index])
                        .offset(x: cloudOffsets[index],
                               y: -geometry.size.height * [0.3, 0.4, 0.25][index])
                }
                .onAppear {
                    // 云的移动动画，每个云速度和起始位置不同
                    for index in 0..<3 {
                        withAnimation(
                            .linear(duration: Double.random(in: 25...35))
                            .repeatForever(autoreverses: false)
                        ) {
                            cloudOffsets[index] = geometry.size.width
                        }
                        
                        // 云的缩放动画，每个云的时间和幅度不同
                        withAnimation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                        ) {
                            cloudScales[index] = Double.random(in: 1.1...1.2)
                        }
                    }
                }
                
                // 地面装饰
                HStack {
                    // 左侧
                    VStack {
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-15))
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    
                    Spacer()
                    
                    // 右侧
                    VStack {
                        Image("sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(15))
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 50)
            }
        }
    }
    
    private var colors: [Color] {
        switch timeOfDay {
        case .day:
            return [
                Color(red: 0.4, green: 0.7, blue: 0.9),
                Color(red: 0.6, green: 0.8, blue: 0.95)
            ]
        case .night:
            return [
                Color(red: 0.1, green: 0.15, blue: 0.3),
                Color(red: 0.15, green: 0.2, blue: 0.35)
            ]
        }
    }
}

struct WeatherBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeatherBackgroundView(timeOfDay: .day)
                .previewDisplayName("Day")
            
            WeatherBackgroundView(timeOfDay: .night)
                .previewDisplayName("Night")
        }
    }
}
