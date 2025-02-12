import SwiftUI

struct CircleTriangleView: View {
    let pointingUp: Bool
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Circle background
            Circle()
                .fill(.white.opacity(0.2))  // Semi-transparent white circle
                .frame(width: size, height: size)
            
            // Larger triangle
            Image(systemName: pointingUp ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: size * 0.8)) // Make triangle larger relative to circle
                .foregroundColor(.white)  // White triangle
        }
    }
}

#Preview {
    HStack {
        CircleTriangleView(pointingUp: true, size: 16)
        CircleTriangleView(pointingUp: false, size: 16)
    }
    .background(Color.blue)
}
