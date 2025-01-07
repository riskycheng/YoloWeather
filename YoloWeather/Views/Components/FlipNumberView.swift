import SwiftUI

struct FlipNumberView: View {
    let value: Int
    let unit: String
    let color: Color
    @State private var animationCount: Int
    
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
