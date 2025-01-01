import SwiftUI

struct DigitalDisplayText: View {
    let text: String
    var fontSize: CGFloat = 200
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .thin))
            .minimumScaleFactor(0.1)
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        .white,
                        .white.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .white.opacity(0.8), radius: 10, x: 0, y: 0)
            .shadow(color: .white.opacity(0.5), radius: 20, x: 0, y: 0)
            .overlay {
                Text(text)
                    .font(.system(size: fontSize, weight: .thin))
                    .minimumScaleFactor(0.1)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.5)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 1, y: 1)
                    .blendMode(.overlay)
            }
            .overlay {
                // Glass reflection effect
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.7, y: geometry.size.height * 0.2))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.3, y: geometry.size.height * 0.2))
                        path.closeSubpath()
                    }
                    .fill(
                        .linearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .blendMode(.overlay)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        .linearGradient(
                            colors: [
                                Color(white: 0.1).opacity(0.7),
                                Color(white: 0.05).opacity(0.8)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                    .blur(radius: 1)
            }
            .padding()
    }
}

#Preview {
    ZStack {
        Color.blue
        DigitalDisplayText(text: "12")
    }
}
