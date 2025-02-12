import SwiftUI

struct TemperatureTrendArrow: View {
    let highTemperature: Double
    let lowTemperature: Double
    let timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        Canvas { context, size in
            // Draw curved arrow
            let path = Path { p in
                let startPoint = CGPoint(x: size.width * 0.1, y: size.height * 0.7)
                let endPoint = CGPoint(x: size.width * 0.9, y: size.height * 0.3)
                let controlPoint = CGPoint(x: size.width * 0.5, y: size.height * 0.9)
                
                p.move(to: startPoint)
                p.addQuadCurve(to: endPoint, control: controlPoint)
                
                // Add arrow head
                let arrowLength: CGFloat = 10
                let angle: CGFloat = .pi / 6 // 30 degrees
                
                let dx = endPoint.x - controlPoint.x
                let dy = endPoint.y - controlPoint.y
                let arrowAngle = atan2(dy, dx)
                
                let leftPoint = CGPoint(
                    x: endPoint.x - arrowLength * cos(arrowAngle + angle),
                    y: endPoint.y - arrowLength * sin(arrowAngle + angle)
                )
                let rightPoint = CGPoint(
                    x: endPoint.x - arrowLength * cos(arrowAngle - angle),
                    y: endPoint.y - arrowLength * sin(arrowAngle - angle)
                )
                
                p.move(to: endPoint)
                p.addLine(to: leftPoint)
                p.move(to: endPoint)
                p.addLine(to: rightPoint)
            }
            
            context.stroke(path, with: .color(.red), lineWidth: 2)
            
            // Draw temperatures
            let highText = "\(Int(round(highTemperature)))°"
            let lowText = "\(Int(round(lowTemperature)))°"
            
            context.draw(Text(highText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red), at: CGPoint(x: size.width * 0.95, y: size.height * 0.2))
            
            context.draw(Text(lowText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red), at: CGPoint(x: size.width * 0.05, y: size.height * 0.8))
        }
        .frame(width: 100, height: 60)
    }
}

#Preview {
    ZStack {
        Color.black
        TemperatureTrendArrow(highTemperature: 15, lowTemperature: 8, timeOfDay: .day)
    }
}
