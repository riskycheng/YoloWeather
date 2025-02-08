import SwiftUI
import WeatherKit

struct HourlyForecastView: View {
    let forecast: [CurrentWeather]
    @Environment(\.weatherTimeOfDay) private var timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("24小时预报")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(0..<forecast.count, id: \.self) { index in
                        let weather = forecast[index]
                        let hour = Calendar.current.component(.hour, from: weather.date)
                        
                        VStack(spacing: 8) {
                            Text("\(hour)时")
                                .font(.system(.footnote, design: .monospaced))
                            
                            Image(weather.symbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                            
                            Text("\(Int(round(weather.temperature)))°")
                                .font(.system(.body, design: .monospaced))
                        }
                        .foregroundColor(.black)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(.horizontal)
            }
            .scrollTargetBehavior(.viewAligned)  
            .scrollTargetLayout()  
            .scrollClipDisabled()  
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
        .highPriorityGesture(DragGesture().onChanged { _ in })
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onAppear {
            print("HourlyForecastView - Bottom boundary reached")
        }
    }
}

struct DailyForecast: Identifiable {
    let id = UUID()
    let weekday: String
    let date: Date
    let temperatureMin: Double
    let temperatureMax: Double
    let symbolName: String
    let precipitationProbability: Double?
}

struct DailyForecastView: View {
    let forecast: [DailyForecast]
    @State private var appearingItems: Set<UUID> = []
    
    // 计算7天内的全局温度范围
    private var globalTempRange: (min: Double, max: Double) {
        let minTemp = forecast.map { $0.temperatureMin }.min() ?? 0
        let maxTemp = forecast.map { $0.temperatureMax }.max() ?? 0
        return (minTemp, maxTemp)
    }
    
    private let rowHeight: CGFloat = 52  // 固定每行高度
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(forecast.enumerated()), id: \.element.id) { index, day in
                    dailyWeatherRow(day: day, index: index)
                }
            }
        }
        .frame(height: CGFloat(forecast.count) * rowHeight)  // 根据行数计算总高度
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
        )
        .highPriorityGesture(DragGesture().onChanged { _ in })
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    // 单日天气视图
    private func dailyWeatherRow(day: DailyForecast, index: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 星期
                Text(index == 0 ? "今天" : day.weekday)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 50, alignment: .leading)
                
                // 天气图标和降水概率
                weatherIconView(symbolName: day.symbolName, probability: day.precipitationProbability)
                
                // 温度条和温度
                temperatureView(day: day)
            }
            .frame(height: rowHeight)  // 固定行高
            .padding(.horizontal, 12)
            .opacity(appearingItems.contains(day.id) ? 1 : 0)
            .offset(y: appearingItems.contains(day.id) ? 0 : 20)
            .onAppear {
                let animation = Animation.easeOut(duration: 0.3).delay(Double(index) * 0.05)
                withAnimation(animation) {
                    _ = appearingItems.insert(day.id)
                }
            }
            
            if index != forecast.count - 1 {
                Divider()
                    .background(Color.black.opacity(0.1))
                    .padding(.horizontal, 12)
            }
        }
    }
    
    // 天气图标和降水概率视图
    private func weatherIconView(symbolName: String, probability: Double?) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Image(symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            
            if let probability = probability, probability > 0 {
                Text("\(Int(probability * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.blue.opacity(0.8))
            }
        }
        .frame(width: 40)
    }
    
    // 温度显示视图
    private func temperatureView(day: DailyForecast) -> some View {
        HStack(spacing: 8) {
            Text("\(Int(round(day.temperatureMin)))°")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black.opacity(0.7))
                .frame(width: 35, alignment: .trailing)
                .lineLimit(1)
            
            temperatureBar(low: day.temperatureMin, high: day.temperatureMax)
            
            Text("\(Int(round(day.temperatureMax)))°")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black)
                .frame(width: 35, alignment: .leading)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func temperatureBar(low: Double, high: Double, width: CGFloat = 100) -> some View {
        let (minTemp, maxTemp) = globalTempRange
        let tempRange = maxTemp - minTemp
        
        let lowX = (low - minTemp) / tempRange * width
        let highX = (high - minTemp) / tempRange * width
        
        return ZStack(alignment: .leading) {
            // 背景条
            Capsule()
                .fill(Color(red: 0.9, green: 0.9, blue: 0.95))  // 浅灰色背景
                .frame(width: width, height: 6)
            
            // 温度范围条
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.6, blue: 1.0),  // 蓝色
                            Color(red: 1.0, green: 0.6, blue: 0.4)   // 橙色
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(highX - lowX, 6), height: 6)
                .offset(x: lowX)
        }
        .frame(width: width, height: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .highPriorityGesture(DragGesture().onChanged { _ in })
    }
}

// 预览数据
extension DailyForecast {
    static let previewData = [
        DailyForecast(weekday: "Sun", date: Date(), temperatureMin: 5, temperatureMax: 9, symbolName: "sunny", precipitationProbability: 0.1),
        DailyForecast(weekday: "Mon", date: Date().addingTimeInterval(86400), temperatureMin: 0, temperatureMax: 6, symbolName: "cloudy", precipitationProbability: 0.3),
        DailyForecast(weekday: "Tue", date: Date().addingTimeInterval(172800), temperatureMin: -2, temperatureMax: 7, symbolName: "partly_cloudy_daytime", precipitationProbability: 0.2),
        DailyForecast(weekday: "Wed", date: Date().addingTimeInterval(259200), temperatureMin: -1, temperatureMax: 10, symbolName: "moderate_rain", precipitationProbability: 0.8),
        DailyForecast(weekday: "Thu", date: Date().addingTimeInterval(345600), temperatureMin: 2, temperatureMax: 14, symbolName: "sunny", precipitationProbability: 0.1),
        DailyForecast(weekday: "Fri", date: Date().addingTimeInterval(432000), temperatureMin: 7, temperatureMax: 12, symbolName: "cloudy", precipitationProbability: 0.4),
        DailyForecast(weekday: "Sat", date: Date().addingTimeInterval(518400), temperatureMin: 7, temperatureMax: 11, symbolName: "partly_cloudy_daytime", precipitationProbability: 0.3)
    ]
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        DailyForecastView(forecast: DailyForecast.previewData)
    }
}
