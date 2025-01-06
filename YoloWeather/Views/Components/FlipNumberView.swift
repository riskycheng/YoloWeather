import SwiftUI

struct FlipNumberView: View {
    let value: String
    let fontSize: CGFloat
    let textColor: Color
    @State private var animationTrigger = false
    @State private var previousValue: String
    
    init(value: String, fontSize: CGFloat = 64, textColor: Color = .white) {
        self.value = value
        self.fontSize = fontSize
        self.textColor = textColor
        self._previousValue = State(initialValue: value)
    }
    
    var body: some View {
        ZStack {
            // 上半部分
            VStack(spacing: 0) {
                // 上半部分显示新值
                Text(value)
                    .font(.system(size: fontSize, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(height: fontSize)
                    .clipped()
                    .rotation3DEffect(
                        .degrees(animationTrigger ? 0 : -90),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.5
                    )
                
                // 下半部分显示旧值
                Text(previousValue)
                    .font(.system(size: fontSize, weight: .medium, design: .rounded))
                    .foregroundColor(textColor)
                    .frame(height: fontSize)
                    .clipped()
                    .rotation3DEffect(
                        .degrees(animationTrigger ? 90 : 0),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.5
                    )
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                previousValue = oldValue
                animationTrigger.toggle()
            }
        }
    }
}
