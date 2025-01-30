import SwiftUI
import WeatherKit

struct HourlyForecastView: View {
    let forecast: [CurrentWeather]
    @Environment(\.weatherTimeOfDay) private var timeOfDay: WeatherTimeOfDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("24小时预报")
                .font(.headline)
                .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
            
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
                        .foregroundColor(WeatherThemeManager.shared.textColor(for: timeOfDay))
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
                .fill(.black.opacity(0.2))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.green, lineWidth: 2)
        )
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
    
    // 计算7天内的全局温度范围
    private var globalTempRange: (min: Double, max: Double) {
        let minTemp = forecast.map { $0.temperatureMin }.min() ?? 0
        let maxTemp = forecast.map { $0.temperatureMax }.max() ?? 0
        return (minTemp, maxTemp)
    }
    
    private func temperatureBar(low: Double, high: Double, width: CGFloat = 140) -> some View {
        let (minTemp, maxTemp) = globalTempRange
        let tempRange = maxTemp - minTemp
        
        let lowX = (low - minTemp) / tempRange * width
        let highX = (high - minTemp) / tempRange * width
        
        return ZStack(alignment: .leading) {
            // 背景条
            Capsule()
                .fill(.white.opacity(0.15))
                .frame(width: width, height: 6)
            
            // 温度范围条
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.5),
                            Color.cyan
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: highX - lowX, height: 6)
                .offset(x: lowX)
        }
        .frame(width: width, height: 6)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(forecast) { day in
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            // 星期
                            Text(day.weekday)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 50, alignment: .leading)
                            
                            // 天气图标和降水概率
                            VStack(alignment: .center, spacing: 2) {
                                Image(day.symbolName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                
                                if let probability = day.precipitationProbability, probability > 0 {
                                    Text("\(Int(probability * 100))%")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.cyan)
                                }
                            }
                            .frame(width: 40)
                            
                            // 温度条和温度
                            HStack(spacing: 8) {
                                Text("\(Int(round(day.temperatureMin)))°")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 35, alignment: .trailing)
                                    .lineLimit(1)
                                
                                temperatureBar(low: day.temperatureMin, high: day.temperatureMax)
                                
                                Text("\(Int(round(day.temperatureMax)))°")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 35, alignment: .leading)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        if forecast.firstIndex(where: { $0.id == day.id }) != forecast.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 12)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 460)  // 增加视图高度
        .onAppear {
            print("DailyForecastView - Bottom boundary reached at height: 460")
        }
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
