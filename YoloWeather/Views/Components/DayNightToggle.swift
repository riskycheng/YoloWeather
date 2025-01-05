import SwiftUI

struct DayNightToggle: View {
    @Binding var isNight: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isNight.toggle()
            }
        }) {
            ZStack {
                // Background Capsule
                Capsule()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 70, height: 32)
                
                // Toggle Circle with Icon
                HStack {
                    if !isNight {
                        Spacer()
                    }
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: isNight ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(isNight ? .black : .yellow)
                    }
                    .padding(.horizontal, 2)
                    
                    if isNight {
                        Spacer()
                    }
                }
                .frame(width: 70)
            }
        }
    }
}

#Preview {
    DayNightToggle(isNight: .constant(false))
}
