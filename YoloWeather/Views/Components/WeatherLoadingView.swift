import SwiftUI

struct WeatherLoadingView: View {
    @Environment(\.weatherTimeOfDay) private var timeOfDay
    
    @State private var rotationAngle = 0.0
    @State private var scaleEffect = 1.0
    @State private var cloudOffset: CGFloat = -50
    @State private var cloudOpacity = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            
            ZStack {
                // 主要天气图标（太阳/月亮）
                Image(timeOfDay == .day ? "sunny" : "full_moon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(rotationAngle))
                    .scaleEffect(scaleEffect)
                
                // 云朵1
                Image("cloudy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .offset(x: cloudOffset)
                    .opacity(cloudOpacity)
                
                // 云朵2
                Image("cloudy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .offset(x: -cloudOffset, y: 15)
                    .opacity(cloudOpacity)
            }
            .position(x: centerX, y: centerY)
        }
        .onAppear {
            // 主图标旋转动画
            withAnimation(
                .linear(duration: 2)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
            
            // 缩放动画
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                scaleEffect = 1.1
            }
            
            // 云朵动画
            withAnimation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true)
            ) {
                cloudOffset = 50
                cloudOpacity = 0.8
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        WeatherLoadingView()
    }
    .environment(\.weatherTimeOfDay, .day)
}