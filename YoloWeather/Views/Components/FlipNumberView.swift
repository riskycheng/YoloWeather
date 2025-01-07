import SwiftUI

struct FlipNumberView: View {
    let value: Int
    let unit: String
    let color: Color
    @State private var animationCount: Int
    @State private var animationId = UUID()
    
    init(value: Int, unit: String = "", color: Color = .white) {
        self.value = value
        self.unit = unit
        self.color = color
        self._animationCount = State(initialValue: value)
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("\(animationCount)")
                .contentTransition(.numericText(value: Double(animationCount)))
                .foregroundColor(color)
                .id(animationId)
            
            if !unit.isEmpty {
                Text(unit)
                    .foregroundColor(color)
            }
        }
        .onChange(of: value) { oldValue, newValue in
            animationId = UUID()
            withAnimation(
                .spring(
                    duration: 0.8,
                    bounce: 0.4,
                    blendDuration: 0.4
                )
            ) {
                animationCount = newValue
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
