import SwiftUI

struct LoadingPlaceholderView: View {
    @State private var opacity: Double = 0.3
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.white)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.7
                }
            }
    }
}

struct LoadingPlaceholderRow: View {
    let width: CGFloat
    let height: CGFloat = 24
    
    var body: some View {
        LoadingPlaceholderView()
            .frame(width: width, height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingPlaceholderRow(width: 200)
        LoadingPlaceholderRow(width: 150)
        LoadingPlaceholderRow(width: 180)
    }
    .padding()
    .background(Color.blue)
} 