import SwiftUI

struct FlipNumberView: View {
    let value: Int
    let unit: String
    let color: Color
    let trigger: UUID?
    @State private var animationCount: Int
    @State private var opacity: Double = 1
    
    init(value: Int, unit: String = "", color: Color = .white, trigger: UUID? = nil) {
        self.value = value
        self.unit = unit
        self.color = color
        self.trigger = trigger
        self._animationCount = State(initialValue: value)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(animationCount)")
                .contentTransition(.numericText(value: Double(animationCount)))
                .foregroundColor(color)
                .opacity(opacity)
            
            if !unit.isEmpty {
                Text(unit)
                    .foregroundColor(color)
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                animationCount = newValue
            }
        }
        .onChange(of: trigger) { oldValue, newValue in
            // Create a fade out/in animation
            withAnimation(.easeInOut(duration: 0.15)) {
                opacity = 0
            }
            
            // Fade back in
            withAnimation(.easeInOut(duration: 0.15).delay(0.15)) {
                opacity = 1
            }
        }
    }
}

struct FlipNumberView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            FlipNumberView(value: 25, unit: "°")
                .font(.system(size: 96, weight: .thin))
        }
    }
}
