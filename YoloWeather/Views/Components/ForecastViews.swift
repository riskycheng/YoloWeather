import SwiftUI

struct HourlyForecastView: View {
    let forecast: [WeatherInfo]
    let hourFormatter: DateFormatter
    
    var body: some View {
        VStack(spacing: 4) {
            // Time slots
            HStack(spacing: 0) {
                Text("现在")
                    .frame(maxWidth: .infinity)
                ForEach(Array(forecast.prefix(5)), id: \.date) { weather in
                    Text(hourFormatter.string(from: weather.date))
                        .frame(maxWidth: .infinity)
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            
            // Temperature trend bar
            if let currentTemp = forecast.first?.temperature,
               let maxTemp = forecast.prefix(6).map({ $0.temperature }).max(),
               let minTemp = forecast.prefix(6).map({ $0.temperature }).min() {
                TemperatureBar(progress: CGFloat((currentTemp - minTemp) / (maxTemp - minTemp)))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal)
    }
}

struct DailyForecastView: View {
    let forecast: [DayWeatherInfo]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(forecast, id: \.date) { weather in
                HStack {
                    Text(weather.date, style: .date)
                        .font(.system(size: 16, weight: .medium))
                    
                    Spacer()
                    
                    Text("\(Int(round(weather.lowTemperature)))° — \(Int(round(weather.highTemperature)))°")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ExpandableWeatherSection<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack {
            Button {
                withAnimation(.spring(duration: 0.5)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            if isExpanded {
                content()
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 5)
            }
        }
    }
}

struct HourlyForecastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HourlyForecastView(
                forecast: [
                    WeatherInfo(date: Date(), temperature: 25, condition: "Sunny", symbolName: "sun.max.fill"),
                    WeatherInfo(date: Date().addingTimeInterval(3600), temperature: 26, condition: "Sunny", symbolName: "sun.max.fill"),
                    WeatherInfo(date: Date().addingTimeInterval(7200), temperature: 27, condition: "Sunny", symbolName: "sun.max.fill"),
                    WeatherInfo(date: Date().addingTimeInterval(10800), temperature: 28, condition: "Sunny", symbolName: "sun.max.fill"),
                    WeatherInfo(date: Date().addingTimeInterval(14400), temperature: 24, condition: "Sunny", symbolName: "sun.max.fill"),
                    WeatherInfo(date: Date().addingTimeInterval(18000), temperature: 23, condition: "Sunny", symbolName: "sun.max.fill")
                ],
                hourFormatter: {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH"
                    return formatter
                }()
            )
            .padding()
            .background(.ultraThinMaterial)
            
            Spacer().frame(height: 40)
            
            DailyForecastView(
                forecast: [
                    DayWeatherInfo(date: Date(), condition: "Sunny", symbolName: "sun.max.fill", lowTemperature: 20, highTemperature: 30),
                    DayWeatherInfo(date: Date().addingTimeInterval(86400), condition: "Cloudy", symbolName: "cloud.fill", lowTemperature: 19, highTemperature: 28),
                    DayWeatherInfo(date: Date().addingTimeInterval(172800), condition: "Rain", symbolName: "cloud.rain.fill", lowTemperature: 18, highTemperature: 25)
                ]
            )
        }
        .padding()
        .background(Color(white: 0.95))
    }
}
