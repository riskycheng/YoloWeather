import SwiftUI

struct WeatherBackgroundView: View {
    let timeOfDay: WeatherTimeOfDay
    @State private var cloudOffset: CGFloat = -200
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.8, blue: 1.0),  // Light blue sky
                        Color(red: 0.6, green: 0.9, blue: 1.0)   // Lighter blue horizon
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Animated clouds
                ForEach(0..<3) { index in
                    Image(systemName: "cloud.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 100)
                        .offset(x: cloudOffset + CGFloat(index * 200), y: CGFloat(50 + index * 30))
                        .onAppear {
                            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                                cloudOffset = geometry.size.width
                            }
                        }
                }
                
                // Nature scene
                VStack {
                    Spacer()
                    ZStack {
                        // Background trees
                        HStack(spacing: -10) {
                            ForEach(0..<8) { index in
                                Image(systemName: "tree.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.green.opacity(0.6))
                                    .frame(height: 60 + CGFloat(index % 3) * 20)
                                    .offset(y: CGFloat(index % 2) * 10)
                            }
                        }
                        .padding(.bottom, -20)
                        
                        // Foreground elements
                        HStack {
                            // Left side vegetation
                            VStack {
                                Image(systemName: "leaf.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.green.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(-30))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            // Right side vegetation
                            VStack {
                                Image(systemName: "leaf.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.green.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .rotationEffect(.degrees(30))
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal)
                    }
                }
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
